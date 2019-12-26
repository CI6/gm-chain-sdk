ROOTDIR=`pwd`

if [ -d output_ios ]; then
  rm -rf output_ios
fi
mkdir output_ios

# 编译库路径
SOURCE_DIR_IOS="secp256k1_ios"
cd $SOURCE_DIR_IOS

# 内部输出路径
OUTPUT_DIR="output"

# 合并架构路径
FAT="$OUTPUT_DIR/fat-libs"

# 单独架构路径路径
THIN=`pwd`/"$OUTPUT_DIR/thin-libs"

# 编译标志
CONFIGURE_FLAGS="--disable-shared --disable-frontend --enable-module-recovery"

# 编译架构
ARCHS="arm64 armv7s x86_64 i386 armv7"

# 自动生成配置
make distclean
./autogen.sh

echo "building thin libraries..."
mkdir -p $THIN

# 工作路径保存
CURR_WORK_DIR=`pwd`

# 编译核心
compileArch(){
  CURR_ARCH=$1

  echo "start building -> $CURR_ARCH"
  mkdir -p "./$OUTPUT_DIR/$CURR_ARCH"
  cd "./$OUTPUT_DIR/$CURR_ARCH"

  if test "$CURR_ARCH" = "i386" -o "$CURR_ARCH" = "x86_64" 
  then
    PLATFORM="iPhoneSimulator"
    if test "$CURR_ARCH" = "x86_64" 
    then
      SIMULATOR="-mios-simulator-version-min=7.0"
      HOST=x86_64-apple-darwin
    else
      SIMULATOR="-mios-simulator-version-min=5.0"
      HOST=i386-apple-darwin
    fi
  else
    PLATFORM="iPhoneOS"
    SIMULATOR=
    HOST=arm-apple-darwin
  fi

  XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
  CC="xcrun -sdk $XCRUN_SDK clang -arch $CURR_ARCH"

  CFLAGS="-arch $CURR_ARCH $SIMULATOR -DENABLE_MODULE_RECOVERY"
  CXXFLAGS="$CFLAGS"
  LDFLAGS="$CFLAGS"

  CC=$CC $CURR_WORK_DIR/configure $CONFIGURE_FLAGS --host=$HOST --prefix="$THIN/$CURR_ARCH" CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
  make -j3 install
  cd $CURR_WORK_DIR
}

# 交叉编译(ios全部架构包含xcode模拟器)
compileArch armv7
compileArch armv7s
compileArch arm64
compileArch i386
compileArch x86_64

# 合并架构
echo "building fat ..."
mkdir -p $FAT/lib
set - $ARCHS
CURR_WORK_DIR=`pwd`
cd $THIN/$1/lib
for LIB in *.a
do
  cd $CURR_WORK_DIR
  lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
done

# 拷贝文件 & 清理
cd $CURR_WORK_DIR
cp -rf $THIN/$1/include $FAT

cd $ROOTDIR
cp -rf $SOURCE_DIR_IOS/$FAT output_ios
rm -rf "$SOURCE_DIR_IOS/$OUTPUT_DIR"

echo "build success, target -> output_ios"

