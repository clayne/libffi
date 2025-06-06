#!/bin/bash

if ! [ -x "$(command -v emcc)" ]; then
  echo "Error: emcc could not be found." >&2
  exit 1
fi

# Common compiler flags
export CFLAGS="-fPIC $EXTRA_CFLAGS"
export CXXFLAGS="$CFLAGS -sNO_DISABLE_EXCEPTION_CATCHING $EXTRA_CXXFLAGS"
export LDFLAGS="-sEXPORTED_FUNCTIONS=_main,_malloc,_free -sALLOW_TABLE_GROWTH -sASSERTIONS -sNO_DISABLE_EXCEPTION_CATCHING -sWASM_BIGINT"

# Specific variables for cross-compilation
export CHOST="wasm32-unknown-linux" # wasm32-unknown-emscripten

wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 -qO - https://ftpmirror.gnu.org/autoconf/autoconf-2.72.tar.gz | tar -xvzf -
mkdir -p ~/i
(cd autoconf-2.72; ./configure --prefix=$HOME/i; make; make install)

# Special build tools are here...
export PATH=$HOME/i/bin:$PATH

autoreconf -fiv
emconfigure ./configure --prefix="$(pwd)/target" --host=$CHOST --enable-static --disable-shared \
  --disable-builddir --disable-multi-os-directory --disable-raw-api --disable-docs ||
  (cat config.log && exit 1)
make

EMMAKEN_JUST_CONFIGURE=1 emmake make check \
  RUNTESTFLAGS="LDFLAGS_FOR_TARGET='$LDFLAGS'" || (cat testsuite/libffi.log && exit 1)
