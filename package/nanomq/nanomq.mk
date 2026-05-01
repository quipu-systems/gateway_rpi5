################################################################################
#
# nanomq
#
################################################################################

NANOMQ_VERSION = 0.24.13
#NANOMQ_SITE = $(call github,nanomq,nanomq,$(NANOMQ_VERSION))
NANOMQ_SITE = https://github.com/nanomq/nanomq.git
NANOMQ_SITE_METHOD = git
NANOMQ_LICENSE = MIT
NANOMQ_LICENSE_FILES = LICENSE.txt
NANOMQ_INSTALL_STAGING = NO
NANOMQ_SUPPORTS_IN_SOURCE_BUILD = NO

# Enable git submodules for build dependencies
NANOMQ_GIT_SUBMODULES = YES

# Use CMake with Ninja backend
NANOMQ_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS=OFF \
	-DBUILD_STATIC_LIBS=OFF \
	-DNNG_ENABLE_TLS=$(if $(BR2_PACKAGE_MBEDTLS),ON,OFF)

# QUIC support
ifeq ($(BR2_PACKAGE_NANOMQ_QUIC),y)
NANOMQ_CONF_OPTS += \
	-DNNG_ENABLE_QUIC=ON \
	-DINTERNAL_MSQUIC_INCLUDE_DIR=$(@D)/nng/extern/msquic/src/inc

# Fix OpenSSL cross-compile: on x86_64 hosts, OpenSSL's 'config' script
# auto-detects linux-x86_64 instead of the aarch64 target, causing -m64 errors.
# Replace 'config' with explicit 'Configure linux-aarch64'.
define NANOMQ_FIX_OPENSSL_CROSS_COMPILE
	find $(@D) \( -name "*.cmake" -o -name "CMakeLists.txt" -o -name "*.cmake.in" \) \
		-print0 | xargs -0 grep -rl "openssl/config" 2>/dev/null | \
		xargs --no-run-if-empty $(SED) 's|openssl/config\b|openssl/Configure linux-aarch64|g' && \
	echo "OpenSSL cross-compile fix applied (or no matches found, which is OK)"
endef

ifeq ($(shell uname -m),x86_64)
NANOMQ_POST_EXTRACT_HOOKS += NANOMQ_FIX_OPENSSL_CROSS_COMPILE
endif
endif

# CLI client tools
ifeq ($(BR2_PACKAGE_NANOMQ_CLI),y)
NANOMQ_CONF_OPTS += -DBUILD_CLIENT=ON
endif

# SQLite support
ifeq ($(BR2_PACKAGE_NANOMQ_SQLITE),y)
NANOMQ_CONF_OPTS += -DNNG_ENABLE_SQLITE=ON
endif

# JWT authentication
ifeq ($(BR2_PACKAGE_NANOMQ_JWT),y)
NANOMQ_CONF_OPTS += -DENABLE_JWT=ON
endif

# ZeroMQ gateway
ifeq ($(BR2_PACKAGE_NANOMQ_ZMQ_GATEWAY),y)
NANOMQ_CONF_OPTS += -DBUILD_ZMQ_GATEWAY=ON
endif

# NFTP support
ifeq ($(BR2_PACKAGE_NANOMQ_NFTP),y)
NANOMQ_CONF_OPTS += -DBUILD_NFTP=ON
endif

# DDS proxy
ifeq ($(BR2_PACKAGE_NANOMQ_DDS_PROXY),y)
NANOMQ_CONF_OPTS += -DBUILD_DDS_PROXY=ON
endif

# MQTT benchmark tool
ifeq ($(BR2_PACKAGE_NANOMQ_BENCH),y)
NANOMQ_CONF_OPTS += -DBUILD_BENCH=ON
endif

# Add mbedtls as optional dependency
ifeq ($(BR2_PACKAGE_MBEDTLS),y)
NANOMQ_DEPENDENCIES += mbedtls
endif

# Install configuration file
define NANOMQ_INSTALL_CONFIG
	$(INSTALL) -D -m 0644 $(@D)/etc/nanomq.conf \
		$(TARGET_DIR)/etc/nanomq.conf
endef

NANOMQ_POST_INSTALL_TARGET_HOOKS += NANOMQ_INSTALL_CONFIG

# Install init script
define NANOMQ_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 0755 $(NANOMQ_PKGDIR)/S50nanomq \
		$(TARGET_DIR)/etc/init.d/S50nanomq
endef

$(eval $(cmake-package))
