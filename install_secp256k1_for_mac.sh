SOURCE_DIR_IOS="secp256k1"
cd $SOURCE_DIR_IOS

./autogen.sh
./configure
make
make check
sudo make install