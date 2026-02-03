#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.
# Edited by: Kenneth Alcineus
# Attributed when relevant to: https://github.com/cu-ecen-aeld/assignments-3-and-later-mu2d2/blob/main/finder-app/manual-linux.sh

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # DONE: Add your kernel build steps here
    echo "Building ${ARCH} kernel with ${CROSS_COMPILE}gcc"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/Image

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# DONE: Create necessary base directories - directories attributed to Muthuu SVS (https://github.com/cu-ecen-aeld/assignments-3-and-later-mu2d2/blob/main/finder-app/manual-linux.sh)
echo "Creating rootfs directories"
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs

mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # DONE: Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# DONE: Make and install busybox
echo "Building busybox"
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# DONE: Add library dependencies to rootfs - sed regex and library iteration logic attributed to Muthuu SVS (https://github.com/cu-ecen-aeld/assignments-3-and-later-mu2d2/blob/main/finder-app/manual-linux.sh)
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
INTERPRETER=$(${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | sed -n 's/.*program interpreter: \(.*\)\]/\1/p')
cp -a ${SYSROOT}${INTERPRETER} ${OUTDIR}/rootfs${INTERPRETER}

mkdir -p ${OUTDIR}/rootfs/lib 
mkdir -p ${OUTDIR}/rootfs/lib64

LIBRARIES=$(${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p')

echo "Copying libraries"
for LIB in ${LIBRARIES}; do
    if [ -e ${SYSROOT}/lib/${LIB} ]; then
        cp -a ${SYSROOT}/lib/${LIB} ${OUTDIR}/rootfs/lib/
    else
        cp -a ${SYSROOT}/lib64/${LIB} ${OUTDIR}/rootfs/lib64/
    fi
done

# DONE: Make device nodes
echo "Creating device nodes"

sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# DONE: Clean and build the writer utility
echo "Building writer utility"

cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# DONE: Copy the finder related scripts and executables to the /home directory
# on the target rootfs 
echo "Copying scripts"

cp -a ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/

chmod +x ${OUTDIR}/rootfs/home/writer
chmod +x ${OUTDIR}/rootfs/home/finder.sh
chmod +x ${OUTDIR}/rootfs/home/finder-test.sh
chmod +x ${OUTDIR}/rootfs/home/autorun-qemu.sh

rm -f ${OUTDIR}/rootfs/conf
rm -f ${OUTDIR}/rootfs/home/conf

mkdir -p ${OUTDIR}/rootfs/conf
mkdir -p ${OUTDIR}/rootfs/home/conf

cp -a ${FINDER_APP_DIR}/conf/. ${OUTDIR}/rootfs/conf/
cp -a ${FINDER_APP_DIR}/conf/. ${OUTDIR}/rootfs/home/conf/

# DONE: Chown the root directory
echo "Updating root directory ownership"
sudo chown -R root:root ${OUTDIR}/rootfs

# DONE: Create initramfs.cpio.gz
echo "Creating initramfs"

cd ${OUTDIR}/rootfs
find . | cpio -ov --format newc --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

echo "Kernel build complete!"