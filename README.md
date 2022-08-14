# qt-creator-build

Dockerfile that builds [Qt-Creator](https://code.qt.io/cgit/qt-creator/qt-creator.git/) from sources with all necessary dependencies.

```sh
mkdir ./install
docker build -t qtc-build .
docker run --rm -ti -v `realpath ./install`:/root/install qtc-build
```
Archive with Qt-Creator will be appeared at install directory.
