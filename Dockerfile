ARG DEBIAN_DIST=bookworm
FROM debian:bookworm

ARG DEBIAN_DIST
ARG zed_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG zed_RELEASE

RUN mkdir -p /output/usr/bin/zed.app
RUN mkdir -p /output/usr/lib/zed.app
RUN mkdir -p /output/usr/libexec
RUN mkdir -p /output/DEBIAN

COPY zed.app/bin/* /output/usr/bin/
COPY zed.app/lib/* /output/usr/lib/zed.app/
COPY zed.app/libexec/* /output/usr/libexec/
COPY zed.app/share /output/usr/share/
RUN mkdir -p /output/usr/share/doc/zed

COPY output/DEBIAN/control /output/DEBIAN/
COPY output/copyright /output/usr/share/doc/zed/
COPY output/changelog.Debian /output/usr/share/doc/zed/
COPY output/README.md /output/usr/share/doc/zed/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/zed/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/zed/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/zed_VERSION/$zed_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

RUN dpkg-deb --build /output /zed_${FULL_VERSION}.deb
