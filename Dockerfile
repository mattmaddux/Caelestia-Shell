FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
        base-devel git \
        cmake ninja pkgconf \
        qt6-base qt6-declarative qt6-shadertools \
        aubio pipewire libqalculate \
    && pacman -Scc --noconfirm

RUN useradd -m builder \
    && echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER builder
WORKDIR /home/builder
RUN git clone https://aur.archlinux.org/libcava.git \
    && cd libcava \
    && makepkg -si --noconfirm \
    && cd .. && rm -rf libcava

USER root
RUN git config --system --add safe.directory '*'

WORKDIR /workspace
CMD ["bash"]
