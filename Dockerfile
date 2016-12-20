FROM nvidia/cuda:8.0-cudnn5-devel

MAINTAINER Luis Mesas <luis.mesas@intelygenz.com>

ARG THEANO_VERSION=rel-0.8.2
ARG KERAS_VERSION=1.1.2
ARG OPENCV_VERSION=3.1.0

# Base dependencies
RUN apt-get update && apt-get install -y build-essential cmake checkinstall git pkg-config \
    && \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Common libraries
RUN apt-get update && apt-get install -y \
        libavcodec-dev \
		libavformat-dev \
		libdc1394-22-dev \
		libffi-dev \
		libfreetype6-dev \
		libgtk2.0-dev \
		libhdf5-dev \
		libjasper-dev \
		libjpeg-dev \
		liblcms2-dev \
		libopenblas-dev \
		liblapack-dev \
		libopenjpeg2 \
		libpng-dev \
		libssl-dev \
		libswscale-dev \
		libtbb2 \
		libtbb-dev \
        libtiff-dev \
		libwebp-dev \
		libzmq3-dev \
#		libpng12-dev \
#		libtiff5-dev \
    && \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# GStreamer support
RUN apt-get update && apt-get install -y \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
    && \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# other dependencies
RUN apt-get update && apt-get install -y \
		bc \
		curl \
		g++ \
		gfortran \
		software-properties-common \
		unzip \
		vim \
		wget \
		zlib1g-dev \
    && \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Link BLAS library to use OpenBLAS using the alternatives mechanism (https://www.scipy.org/scipylib/building/linux.html#debian-ubuntu)
RUN apt-get update && update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3 \
    && \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install useful Python packages using apt-get to avoid version incompatibilities with Tensorflow binary
# especially numpy, scipy, skimage and sklearn (see https://github.com/tensorflow/tensorflow/issues/2034)
RUN apt-get update && apt-get install -y \
        python-dev \
		python-numpy \
		python-scipy \
		python-nose \
		python-h5py \
		python-skimage \
		python-matplotlib \
		python-pandas \
		python-sklearn \
		python-sympy \
    && \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install pip
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
	python get-pip.py && \
	rm get-pip.py

# Add SNI support to Python
RUN pip --no-cache-dir install \
		pyopenssl \
		ndg-httpsclient \
		pyasn1

# Install Open CV
RUN curl -L https://github.com/Itseez/opencv/archive/${OPENCV_VERSION}.zip -o opencv.zip && \
    unzip opencv.zip && \
    rm opencv.zip && \
    mkdir opencv-${OPENCV_VERSION}/release && \
    cd opencv-${OPENCV_VERSION}/release && \
    cmake -D WITH_CUDA=ON -D CUDA_ARCH_BIN="5.3" -D CUDA_ARCH_PTX="" -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make && \
    make install && \
    cd ../.. &&\
    rm -rf opencv-${OPENCV_VERSION}

# Install other useful Python packages using pip
RUN pip --no-cache-dir install --upgrade ipython && \
	pip --no-cache-dir install \
		Cython \
		ipykernel \
		jupyter \
		path.py \
		Pillow \
		pygments \
		six \
		sphinx \
		wheel \
		zmq \
		&& \
	python -m ipykernel.kernelspec

# Install Theano and set up Theano config (.theanorc) for CUDA and OpenBLAS
RUN pip --no-cache-dir install git+git://github.com/Theano/Theano.git@${THEANO_VERSION} && \
	\
	echo "[global]\ndevice=gpu\nfloatX=float32\noptimizer_including=cudnn\nmode=FAST_RUN \
		\n[lib]\ncnmem=0.95 \
		\n[nvcc]\nfastmath=True \
		\n[blas]\nldflag = -L/usr/lib/openblas-base -lopenblas \
		\n[DebugMode]\ncheck_finite=1" \
	> /root/.theanorc

# Install Keras
RUN pip --no-cache-dir install git+git://github.com/fchollet/keras.git@${KERAS_VERSION}

# Working directory
WORKDIR "/root"
CMD ["/bin/bash"]
