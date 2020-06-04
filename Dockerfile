# ##########   #######   ############
FROM ecr.vip.ebayc3.com/sds/sds_cpp_base:3.12
LABEL description="Automated SDS compilation"

ARG BRANCH_NAME
ARG BUILD_TYPE
ARG COVERAGE_ON
ARG CONAN_CHANNEL
ARG ARTIFACTORY_PASS=${ARTIFACTORY_PASS}
ARG CONAN_USER
ARG HOMESTORE_BUILD_TAG

ENV BRANCH_NAME=${BRANCH_NAME:-unknown}
ENV BUILD_TYPE=${BUILD_TYPE:-default}
ENV COVERAGE_ON=${COVERAGE_ON:-false}
ENV ARTIFACTORY_PASS=${ARTIFACTORY_PASS:-password}
ENV CONAN_USER=${CONAN_USER:-sds}
ENV CONAN_CHANNEL=${CONAN_CHANNEL:-develop}
ENV HOMESTORE_BUILD_TAG=${HOMESTORE_BUILD_TAG:-release}
ENV SOURCE_PATH=/tmp/source/

COPY .git/ ${SOURCE_PATH}.git
RUN cd ${SOURCE_PATH}; git reset --hard

WORKDIR /output
ENV ASAN_OPTIONS=detect_leaks=0

RUN set -eux; \
    eval $(grep 'name =' ${SOURCE_PATH}conanfile.py | sed 's, ,,g' | sed 's,name,PKG_NAME,'); \
    eval $(grep -m 1 'version =' ${SOURCE_PATH}conanfile.py | sed 's, ,,g' | sed 's,version,PKG_VERSION,'); \
    if [ "debug" = "${BUILD_TYPE}" ] && [ "true" = "${COVERAGE_ON}" ]; then \
      conan install --build missing -o ${PKG_NAME}:coverage=True -pr ${BUILD_TYPE} ${SOURCE_PATH}; \
      build-wrapper-linux-x86-64 --out-dir /tmp/sonar conan build ${SOURCE_PATH}; \
      find . -name "*.gcno" -exec gcov {} \; ; \
      if [ "develop" != "${BRANCH_NAME}" ]; then \
          echo "sonar.branch.name=${BRANCH_NAME}" >> ${SOURCE_PATH}sonar-project.properties; \
          echo "sonar.branch.target=develop" >> ${SOURCE_PATH}sonar-project.properties; \
      fi; \
      sonar-scanner -Dsonar.projectBaseDir=${SOURCE_PATH} -Dsonar.projectVersion="${PKG_VERSION}"; \
    else \
      conan create -pr ${BUILD_TYPE} ${SOURCE_PATH} "${CONAN_USER}"/"${CONAN_CHANNEL}"; \
    fi;

CMD set -eux; \
    eval $(grep 'name =' ${SOURCE_PATH}conanfile.py | sed 's, ,,g' | sed 's,name,PKG_NAME,'); \
    eval $(grep 'version =' ${SOURCE_PATH}conanfile.py | sed 's, ,,g' | sed 's,version,PKG_VERSION,'); \
    conan user -r ebay-local -p "${ARTIFACTORY_PASS}" _service_sds; \
    conan upload ${PKG_NAME}/${PKG_VERSION}@"${CONAN_USER}"/"${CONAN_CHANNEL}" -c --all -r ebay-local;
# ##########   #######   ############
