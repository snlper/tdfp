#!/bin/bash

INSTALL_LOG="tdfp_install.log"
exec &> >(tee -a "$INSTALL_LOG")

# проверка наличия необходимого ПО
if [ ! -x /usr/bin/curl ]; then
	echo "Install curl"
	touch /dev/null
	exit 1
fi

dpkg-query -s libcurl4-openssl-dev &>>$INSTALL_LOG
if [[ $? == 1 ]]; then
	echo "Need to install libcurl4-openssl-dev"
	read -p "Install? (yes/no) " yn
	case $yn in
		yes )	echo "ok, let me do it";
			sudo apt install -y libcurl4-openssl-dev;;
		no )	echo "exiting...";
			exit 3;;
		* )	echo "invalid response";
			exit 4;;
	esac
fi

# frei0r-plugins-dev
# libchromaprint-dev

WORKING_FOLDER=$PWD
JOBS_COUNT=$(cat /proc/cpuinfo | grep processor | wc -l)

# загрузка всей хуйни

# переменные transmission-cli
# начало ссылки на исходники transmission
BEGIN_TORRENT_URL="https://build.transmissionbt.com/job/trunk-linux/"
# конец ссылки с именем архива transmission
END_TORRENT_URL=$(curl -v --silent https://build.transmissionbt.com/job/trunk-linux/ 2>&1 | grep -Eo "lastSuccessfulBuild/artifact/transmission[a-zA-Z0-9./?=_%:+-]*.tar.xz" | uniq)
# ссылка на transmission
TORRENT_URL=$BEGIN_TORRENT_URL$END_TORRENT_URL
# имя файла архива с исходниками transmission
TORRENT_ARCHIVE_FILE=$(echo $END_TORRENT_URL | sed 's/.*\///')
# имя папки с исходниками transmission
TORRENT_DIR=$(echo $TORRENT_ARCHIVE_FILE | sed -r 's/.tar.xz//')

# переменные ffmpeg
# ссылка на ffmpeg
FFMPEG_URL=$(curl -v --silent https://www.ffmpeg.org/download.html 2>&1 | grep -m1 "https://ffmpeg.org/releases/ffmpeg-" | sed -r 's/(.+tar.xz).+/\1/' | sed 's/.*h/h/')
# имя файла архива ffmpeg
FFMPEG_ARCHIVE_FILE=$(echo $FFMPEG_URL | sed 's/.*\///')
# имя папки с исходниками ffmpeg
FFMPEG_DIR=$(echo $FFMPEG_ARCHIVE_FILE | sed -r 's/.tar.xz//')

# загрузка исходников transmission и ffmpeg
echo -ne 'Downloading sources\n'
echo -ne '[    ]   0%\r'
curl -O --silent $TORRENT_URL
echo -ne '[#   ]  25%\r'
curl -O --silent $FFMPEG_URL
echo -ne '[##  ]  50%\r'

# распаковка исходников
tar xf $TORRENT_ARCHIVE_FILE
echo -ne '[### ]  75%\r'
tar xf $FFMPEG_ARCHIVE_FILE
echo -ne '[####] 100%\n'
echo -ne 'Downloading done\n'

# очистка от скачанных архивов
rm $TORRENT_ARCHIVE_FILE $FFMPEG_ARCHIVE_FILE

# сборка
# сборка transmission
cd $TORRENT_DIR
echo -ne 'Building\n'
echo -ne '[    ]   0%\r'
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo &>>$INSTALL_LOG
cd build
echo -ne '[#   ]  25%\r'
cmake --build . --parallel $JOBS_COUNT &>>$INSTALL_LOG
echo -ne '[##  ]  50%\r'
cd $WORKING_FOLDER

# сборка ffmpeg
cd $FFMPEG_DIR
bash configure --arch=amd64 --enable-gpl --disable-stripping --enable-gnutls --enable-ladspa --enable-libaom --enable-libass --enable-libbluray --enable-libbs2b --enable-libcaca --enable-libcdio --enable-libcodec2 --enable-libdav1d --enable-libflite --enable-libfontconfig --enable-libfreetype --enable-libfribidi --enable-libglslang --enable-libgme --enable-libgsm --enable-libjack --enable-libmp3lame --enable-libmysofa --enable-libopenjpeg --enable-libopenmpt --enable-libopus --enable-libpulse --enable-librabbitmq --enable-librist --enable-librubberband --enable-libshine --enable-libsnappy --enable-libsoxr --enable-libspeex --enable-libsrt --enable-libssh --enable-libsvtav1 --enable-libtheora --enable-libtwolame --enable-libvidstab --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx265 --enable-libxml2 --enable-libxvid --enable-libzimg --enable-libzmq --enable-libzvbi --enable-lv2 --enable-omx --enable-openal --enable-opencl --enable-opengl --enable-sdl2 --disable-sndio --enable-libjxl --enable-pocketsphinx --enable-librsvg --enable-libmfx --enable-libdc1394 --enable-libdrm --enable-libiec61883 --enable-chromaprint --enable-frei0r --enable-libx264 --enable-libplacebo --enable-librav1e --enable-shared &>>$INSTALL_LOG
echo -ne '[### ]  75%\r'
make -j $JOBS_COUNT &>>$INSTALL_LOG
echo -ne '[####]  100%\n'
echo -ne 'Building done\n'

cd $WORKING_FOLDER
ls

