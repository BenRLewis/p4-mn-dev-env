FROM ubuntu:16.04

RUN apt-get update
ADD install_deps.sh install_deps.sh
RUN chmod +x install_deps.sh && ./install_deps.sh
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV NUM_CORES 8
ENV PROTOBUF_COMMIT "v3.2.0"

RUN git clone https://github.com/google/protobuf.git && \
  cd protobuf && git checkout ${PROTOBUF_COMMIT} && \
  export CFLAGS="-Os" && export CXXFLAGS="-Os" && \
  export LDFLAGS="-Wl,-s" && ./autogen.sh && ./configure && \
  make -j${NUM_CORES} && make install && ldconfig && \
  unset CFLAGS CXXFLAGS LDFLAGS && cd python && \
  python setup.py install && cd .. && cd ..

ENV GRPC_COMMIT "v1.3.2"
RUN git clone https://github.com/grpc/grpc.git && cd grpc && \
git checkout ${GRPC_COMMIT} && git submodule update --init --recursive && \
  export LDFLAGS="-Wl,-s" && make -j${NUM_CORES} && sudo make install && \
  sudo ldconfig && unset LDFLAGS && cd .. && sudo pip install grpcio

RUN git clone https://github.com/p4lang/behavioral-model.git && \
cd behavioral-model && tmpdir=`mktemp -d -p .` && cd ${tmpdir} &&\
bash ../travis/install-thrift.sh && bash ../travis/install-nanomsg.sh && \
sudo ldconfig && bash ../travis/install-nnpy.sh cd .. && sudo rm -rf $tmpdir && cd ..

RUN git clone https://github.com/p4lang/PI.git && cd PI && \
git submodule update --init --recursive && ./autogen.sh && ./configure --with-proto && \
make -j${NUM_CORES} && sudo make install && sudo ldconfig && cd ..

RUN cd behavioral-model && ./autogen.sh && ./configure --enable-debugger --with-pi && \
make -j${NUM_CORES} && sudo make install && sudo ldconfig && cd targets/simple_switch_grpc && \
./autogen.sh && ./configure --with-thrift && make -j${NUM_CORES} && sudo make install && \
sudo ldconfig && cd .. && cd .. && cd ..

RUN git clone https://github.com/p4lang/p4c && cd p4c && \
git submodule update --init --recursive && mkdir -p build && cd build && cmake .. && \
make -j${NUM_CORES} && sudo make install && sudo ldconfig && \
cd .. && cd ..
