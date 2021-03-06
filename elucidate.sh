#!/bin/bash

# ELUCIDATE.SH

# This Bash script allows you to easily and safely install Enlightenment 24 along with other EFL-based apps,
# on Ubuntu Focal Fossa; or will help you cleanly uninstall E24.

# See README.md for instructions on how to use this script.

# Heads up!
# Enlightenment programs installed from .deb packages or tarballs will inevitably conflict with
# E24 programs compiled from Git repositories——do not mix source code with pre-built binaries!

# Once installed, you can update your shiny new Enlightenment desktop whenever you want to.
# However, because software gains entropy over time (performance regression, unexpected
# behavior... this is especially true when dealing directly with source code), we
# highly recommend doing a complete uninstall and reinstall of E24 every three
# weeks or so for an optimal user experience.

# ELUCIDATE.SH is written and maintained by batden@sfr.fr and carlasensa@sfr.fr,
# feel free to use this script as you see fit.

# Please consider sending us a tip via https://www.paypal.me/PJGuillaumie
# or starring our repositories to show your support: https://github.com/batden
# Cheers!

# Cool links.
# Eyecandy for your enlightened desktop: https://extra.enlightenment.org/themes/
# Screenshots: https://www.enlightenment.org/ss/

# ---------------
# LOCAL VARIABLES
# ---------------

BLD="\e[1m"    # Bold text.
ITA="\e[3m"    # Italic text.
BDR="\e[1;31m" # Bold red text.
BDG="\e[1;32m" # Bold green text.
BDY="\e[1;33m" # Bold yellow text.
OFF="\e[0m"    # Turn off ANSI colors and formatting.

PREFIX=/usr/local
DLDIR=$(xdg-user-dir DOWNLOAD)
DOCDIR=$(xdg-user-dir DOCUMENTS)
SCRFLR=$HOME/.elucidate
CONFG="./configure --prefix=$PREFIX"
GEN="./autogen.sh --prefix=$PREFIX"
SNIN="sudo ninja -C build install"
SMIL="sudo make install"
RELEASE=$(lsb_release -sc)
ICNV=libiconv-1.16
LWEB=libwebp-1.1.0

# Build dependencies, recommended and script-related packages.
DEPS="aspell build-essential ccache check cmake cowsay ddcutil doxygen faenza-icon-theme \
fonts-noto gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-good \
gstreamer1.0-plugins-ugly imagemagick libasound2-dev libavahi-client-dev \
libblkid-dev libbluetooth-dev libegl1-mesa-dev libexif-dev libfontconfig1-dev \
libdrm-dev libfreetype6-dev libfribidi-dev libgbm-dev libgeoclue-2-dev \
libgif-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libharfbuzz-dev \
libi2c-dev libibus-1.0-dev libinput-dev libjpeg-dev libluajit-5.1-dev \
liblz4-dev libmount-dev libopenjp2-7-dev libosmesa6-dev libpam0g-dev \
libpoppler-cpp-dev libpoppler-dev libpoppler-private-dev libpulse-dev \
libraw-dev librsvg2-dev libscim-dev libsndfile1-dev libspectre-dev \
libssl-dev libsystemd-dev libtiff5-dev libtool libudev-dev libudisks2-dev \
libunibreak-dev libunwind-dev libxcb-keysyms1-dev libxcursor-dev \
libxinerama-dev libxkbcommon-x11-dev libxkbfile-dev libxrandr-dev libxss-dev \
libxtst-dev lolcat manpages-dev manpages-posix-dev meson mlocate ninja-build \
texlive-base unity-greeter-badges valgrind wayland-protocols wmctrl \
xserver-xephyr xwayland zenity"

# Latest development code.
CLONEFL="git clone https://git.enlightenment.org/core/efl.git"
CLONETY="git clone https://git.enlightenment.org/apps/terminology.git"
CLONE24="git clone https://git.enlightenment.org/core/enlightenment.git"
CLONEPH="git clone https://git.enlightenment.org/apps/ephoto.git"
CLONERG="git clone https://git.enlightenment.org/apps/rage.git"
CLONEVI="git clone https://git.enlightenment.org/apps/evisum.git"
CLONEVE="git clone https://git.enlightenment.org/tools/enventor.git"

# ('MN' stands for Meson, 'AT' refers to Autotools)
PROG_MN="efl terminology enlightenment ephoto evisum rage"
PROG_AT="enventor"

# ---------
# FUNCTIONS
# ---------

beep_attention() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
}

beep_question() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-information.oga
}

beep_exit() {
  paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
}

beep_ok() {
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga
}

sel_menu() {
  if [ $INPUT -lt 1 ]; then
    echo
    printf "1. $BDG%s $OFF%s\n\n" "INSTALL Enlightenment 24 from the master branch"
    printf "2. $BDG%s $OFF%s\n\n" "Update and REBUILD Enlightenment 24"
    printf "3. $BDG%s $OFF%s\n\n" "Update and rebuild E24 in RELEASE mode"
    printf "4. $BDY%s $OFF%s\n\n" "Update and rebuild E24 with WAYLAND support"
    printf "5. $BDR%s $OFF%s\n\n" "UNINSTALL all Enlightenment 24 programs"

    # Hints.
    # 1/2: Plain build with well tested default values.
    # 3: A feature-rich, decently optimized build; however, occasionally technical glitches do happen...
    # 4: Same as above, but running Enlightenment as a Wayland compositor is still considered experimental.
    # 5: Nuke 'Em All!

    sleep 1 && printf "$ITA%s $OFF%s\n\n" "Or press Ctrl+C to quit."
    read INPUT
  fi
}

bin_deps() {
  sudo apt update && sudo apt full-upgrade

  sudo apt install $DEPS
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "CONFLICTING OR MISSING .DEB PACKAGES"
    printf "$BDR%s %s\n" "OR DPKG DATABASE IS LOCKED."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  fi
}

ls_dir() {
  COUNT=$(ls -d -- */ | wc -l)
  if [ $COUNT == 7 ]; then
    printf "$BDG%s $OFF%s\n\n" "All programs have been downloaded successfully."
    sleep 2
  elif [ $COUNT == 0 ]; then
    printf "\n$BDR%s %s\n" "OOPS! SOMETHING WENT WRONG."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDY%s %s\n" "WARNING: ONLY $COUNT OF 7 PROGRAMS HAVE BEEN DOWNLOADED!"
    printf "\n$BDY%s $OFF%s\n\n" "WAIT 12 SECONDS OR HIT CTRL+C TO QUIT."
    sleep 12
  fi
}

mng_err() {
  printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
  beep_exit
  exit 1
}

chk_path() {
  if ! echo $PATH | grep -q $HOME/.local/bin; then
    echo -e '    export PATH=$HOME/.local/bin:$PATH' >>$HOME/.bash_aliases
    source $HOME/.bash_aliases
  fi
}

elap_start() {
  START=$(date +%s)
}

elap_stop() {
  DELTA=$(($(date +%s) - $START))
  printf "\n%s" "Compilation and linking time: "
  printf ""%dh:%dm:%ds"\n\n" $(($DELTA / 3600)) $(($DELTA % 3600 / 60)) $(($DELTA % 60))
}

e_bkp() {
  # Timestamp: See the date man page to convert epoch to human-readable date
  # or visit https://www.epochconverter.com/
  TSTAMP=$(date +%s)
  mkdir -p $DOCDIR/ebackups

  mkdir $DOCDIR/ebackups/E_$TSTAMP
  cp -aR $HOME/.elementary $DOCDIR/ebackups/E_$TSTAMP && cp -aR $HOME/.e $DOCDIR/ebackups/E_$TSTAMP

  if [ -d $HOME/.config/terminology ]; then
    cp -aR $HOME/.config/terminology $DOCDIR/ebackups/Eterm_$TSTAMP
  fi

  sleep 2
}

e_tokens() {
  echo $(date +%s) >>$HOME/.cache/ebuilds/etokens

  TOKEN=$(wc -l <$HOME/.cache/ebuilds/etokens)
  if [ "$TOKEN" -gt 3 ]; then
    echo
    # Questions: Enter either y or n, or press Enter to accept the default values.
    beep_question
    read -t 12 -p "Do you want to back up your E24 settings now? [y/N] " answer
    case $answer in
    [yY])
      e_bkp
      ;;
    [nN])
      printf "\n$ITA%s $OFF%s\n\n" "(do not back up my user settings and themes folders... OK)"
      ;;
    *)
      printf "\n$ITA%s $OFF%s\n\n" "(do not back up my user settings and themes folders... OK)"
      ;;
    esac
  fi
}

build_plain() {
  chk_path

  sudo ln -sf /usr/lib/x86_64-linux-gnu/preloadable_libintl.so /usr/lib/libintl.so
  sudo ldconfig

  for I in $PROG_MN; do
    cd $ESRC/e24/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."

    case $I in
    efl)
      meson build
      ninja -C build || mng_err
      ;;
    enlightenment)
      meson build
      ninja -C build || mng_err
      ;;
    *)
      meson build
      ninja -C build || true
      ;;
    esac

    beep_attention
    $SNIN || true
    sudo ldconfig
  done

  for I in $PROG_AT; do
    cd $ESRC/e24/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."

    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
  done
}

rebuild_plain() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  bin_deps
  e_tokens
  elap_start

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  git pull
  meson --reconfigure build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  elap_stop

  for I in $PROG_MN; do
    elap_start

    cd $ESRC/e24/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull
    rm -rf build
    echo

    case $I in
    efl)
      meson build
      ninja -C build || mng_err
      ;;
    enlightenment)
      meson build
      ninja -C build || mng_err
      ;;
    *)
      meson build
      ninja -C build || true
      ;;
    esac

    beep_attention
    $SNIN || true
    sudo ldconfig

    elap_stop
  done

  for I in $PROG_AT; do
    elap_start
    cd $ESRC/e24/$I

    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    sudo make distclean &>/dev/null
    git reset --hard &>/dev/null
    git pull

    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
    elap_stop
  done
}

rebuild_optim_mn() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  bin_deps
  e_tokens
  elap_start

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  git pull
  echo
  sudo chown $USER build/.ninja*
  meson configure -Dexample=false -Dbuildtype=release build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  elap_stop

  for I in $PROG_MN; do
    elap_start

    cd $ESRC/e24/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull

    case $I in
    efl)
      sudo chown $USER build/.ninja*
      meson configure -Dnative-arch-optimization=true -Dfb=true -Dharfbuzz=true \
        -Dbindings=cxx -Dbuild-tests=false -Dbuild-examples=false \
        -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    enlightenment)
      sudo chown $USER build/.ninja*
      meson configure -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    *)
      sudo chown $USER build/.ninja*
      meson configure -Dbuildtype=release build
      ninja -C build || true
      ;;
    esac

    $SNIN || true
    sudo ldconfig

    elap_stop
  done
}

rebuild_optim_at() {
  export CFLAGS="-O2 -ffast-math -march=native"

  for I in $PROG_AT; do
    elap_start
    cd $ESRC/e24/$I

    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    sudo make distclean &>/dev/null
    git reset --hard &>/dev/null
    git pull

    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
    elap_stop
  done
}

rebuild_wld_mn() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  bin_deps
  e_tokens
  elap_start

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  git pull
  echo
  sudo chown $USER build/.ninja*
  meson configure -Dexample=false -Dbuildtype=release build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  elap_stop

  for I in $PROG_MN; do
    elap_start

    cd $ESRC/e24/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    git pull

    case $I in
    efl)
      sudo chown $USER build/.ninja*
      meson configure -Dnative-arch-optimization=true -Dfb=true -Dharfbuzz=true \
        -Dbindings=cxx -Ddrm=true -Dwl=true -Dopengl=es-egl \
        -Dbuild-tests=false -Dbuild-examples=false \
        -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    enlightenment)
      sudo chown $USER build/.ninja*
      meson configure -Dwl=true -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    *)
      sudo chown $USER build/.ninja*
      meson configure -Dbuildtype=release build
      ninja -C build || true
      ;;
    esac

    $SNIN || true
    sudo ldconfig

    elap_stop
  done
}

rebuild_wld_at() {
  export CFLAGS="-O2 -ffast-math -march=native"

  for I in $PROG_AT; do
    elap_start
    cd $ESRC/e24/$I

    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    sudo make distclean &>/dev/null
    git reset --hard &>/dev/null
    git pull

    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
    elap_stop
  done
}

do_tests() {
  if [ -x /usr/bin/wmctrl ]; then
    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
      wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    fi
  fi

  printf "\n\n$BLD%s $OFF%s\n" "System check..."

  if systemd-detect-virt -q --container; then
    printf "\n$BDR%s %s\n" "ELUCIDATE.SH IS NOT INTENDED FOR USE INSIDE CONTAINERS."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  fi

  if [ $RELEASE == focal ]; then
    printf "\n$BDG%s $OFF%s\n\n" "Ubuntu ${RELEASE^}... OK"
    sleep 2
  else
    printf "\n$BDR%s $OFF%s\n\n" "UNSUPPORTED OPERATING SYSTEM [ $(lsb_release -d | cut -f2) ]."
    beep_exit
    exit 1
  fi

  git ls-remote https://git.enlightenment.org/core/efl.git HEAD &>/dev/null
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "REMOTE HOST IS UNREACHABLE——TRY AGAIN LATER"
    printf "$BDR%s $OFF%s\n\n" "OR CHECK YOUR INTERNET CONNECTION."
    beep_exit
    exit 1
  fi

  [[ ! -d $HOME/.local/bin ]] && mkdir -p $HOME/.local/bin

  [[ ! -d $HOME/.cache/ebuilds ]] && mkdir -p $HOME/.cache/ebuilds
}

do_bsh_alias() {
  if [ ! -f $HOME/.bash_aliases ]; then
    touch $HOME/.bash_aliases

    cat >$HOME/.bash_aliases <<EOF
    # ----------------
    # GLOBAL VARIABLES
    # ----------------

    # Compiler and linker flags.
    export CC="ccache gcc"
    export CXX="ccache g++"
    export USE_CCACHE=1
    export CCACHE_COMPRESS=1
    export CPPFLAGS=-I/usr/local/include
    export LDFLAGS=-L/usr/local/lib
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

    # Parallel build? It's your call...
    #export MAKE="make -j$(($(nproc) * 2))"

    # This script adds the ~/.local/bin directory to your PATH environment variable if required.
EOF

    source $HOME/.bash_aliases
  fi
}

set_p_src() {
  echo
  beep_attention
  # Do not append a trailing slash (/) to the end of the path prefix.
  read -p "Please enter a path to the Enlightenment source folders (e.g. /home/jamie or /home/jamie/testing): " mypath
  mkdir -p "$mypath"/sources
  ESRC="$mypath"/sources
  echo $ESRC >$HOME/.cache/ebuilds/storepath
  printf "\n%s\n\n" "You have chosen: $ESRC"
  sleep 1
}

get_preq() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  cd $DLDIR
  printf "\n\n$BLD%s $OFF%s\n\n" "Installing prerequisites..."
  wget -c https://ftp.gnu.org/pub/gnu/libiconv/$ICNV.tar.gz
  tar xzvf $ICNV.tar.gz -C $ESRC
  cd $ESRC/$ICNV
  $CONFG
  make
  sudo make install
  sudo ldconfig
  rm -rf $DLDIR/$ICNV.tar.gz
  echo

  cd $DLDIR
  wget -c https://storage.googleapis.com/downloads.webmproject.org/releases/webp/$LWEB.tar.gz
  tar xzvf $LWEB.tar.gz -C $ESRC
  cd $ESRC/$LWEB
  $CONFG
  make
  sudo make install
  sudo ldconfig
  rm -rf $DLDIR/$LWEB.tar.gz
  echo

  cd $ESRC
  git clone https://github.com/Samsung/rlottie.git
  cd $ESRC/rlottie
  meson build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig
  echo
}

do_lnk() {
  sudo ln -sf /usr/local/etc/enlightenment/sysactions.conf /etc/enlightenment/sysactions.conf
  sudo ln -sf /usr/local/etc/enlightenment/system.conf /etc/enlightenment/system.conf
  sudo ln -sf /usr/local/etc/xdg/menus/e-applications.menu /etc/xdg/menus/e-applications.menu
}

install_now() {
  clear
  printf "\n$BDG%s $OFF%s\n\n" "* INSTALLING ENLIGHTENMENT DESKTOP: PLAIN BUILD *"
  beep_attention
  do_bsh_alias
  bin_deps
  set_p_src
  get_preq

  cd $HOME
  mkdir -p $ESRC/e24
  cd $ESRC/e24

  printf "\n\n$BLD%s $OFF%s\n\n" "Fetching source code from the Enlightened git repositories..."
  $CLONEFL
  echo
  $CLONETY
  echo
  $CLONE24
  echo
  $CLONEPH
  echo
  $CLONERG
  echo
  $CLONEVI
  echo
  $CLONEVE
  echo

  ls_dir

  build_plain

  printf "\n%s\n\n" "Almost done..."

  mkdir -p $HOME/.elementary/themes

  sudo mkdir -p /etc/enlightenment
  do_lnk

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  sudo updatedb
  beep_ok

  printf "\n\n$BDY%s %s" "Initial setup wizard tips:"
  printf "\n$BDY%s %s" "'Update checking' —— you can disable this feature because it serves no useful purpose."
  printf "\n$BDY%s $OFF%s\n\n\n" "'Network management support' —— Connman is not needed."
  # Enlightenment adds three shortcut icons (namely home.desktop, root.desktop and tmp.desktop)
  # to your Ubuntu Desktop, you can safely delete them.

  echo
  cowsay "Now reboot your computer then select Enlightenment on the login screen... \
  That's All Folks!" | lolcat -a
  echo

  cp -f $DLDIR/elucidate.sh $HOME/.local/bin
}

update_go() {
  clear
  printf "\n$BDG%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: PLAIN BUILD *"

  cp -f $SCRFLR/elucidate.sh $HOME/.local/bin
  chmod +x $HOME/.local/bin/elucidate.sh
  sleep 1

  rebuild_plain

  sudo mkdir -p /etc/enlightenment
  do_lnk

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  if [ -f /usr/share/wayland-sessions/enlightenment.desktop ]; then
    sudo rm -rf /usr/share/wayland-sessions/enlightenment.desktop
  fi

  sudo updatedb
  beep_ok
  echo
  cowsay -f www "That's All Folks!"
  echo
}

release_go() {
  clear
  printf "\n$BDG%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: RELEASE BUILD *"

  cp -f $SCRFLR/elucidate.sh $HOME/.local/bin
  chmod +x $HOME/.local/bin/elucidate.sh
  sleep 1

  rebuild_optim_mn
  rebuild_optim_at

  sudo mkdir -p /etc/enlightenment
  do_lnk

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  if [ -f /usr/share/wayland-sessions/enlightenment.desktop ]; then
    sudo rm -rf /usr/share/wayland-sessions/enlightenment.desktop
  fi

  sudo updatedb
  beep_ok
  echo
  cowsay -f www "That's All Folks!"
  echo
}

wld_go() {
  clear
  printf "\n$BDY%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: WAYLAND BUILD *"

  cp -f $SCRFLR/elucidate.sh $HOME/.local/bin
  chmod +x $HOME/.local/bin/elucidate.sh
  sleep 1

  rebuild_wld_mn
  rebuild_wld_at

  sudo mkdir -p /usr/share/wayland-sessions
  sudo ln -sf /usr/local/share/wayland-sessions/enlightenment.desktop \
    /usr/share/wayland-sessions/enlightenment.desktop

  sudo mkdir -p /etc/enlightenment
  do_lnk

  sudo updatedb
  beep_ok

  if [ "$XDG_SESSION_TYPE" == "x11" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo
    cowsay -f www "Now log out of your existing session and press Ctrl+Alt+F3 to switch to tty3, \
        then enter your credentials and type: enlightenment_start" | lolcat -a
    echo
    # Wait a few seconds for the Wayland session to start.
    # When you're done, type exit
    # Pressing Ctrl+Alt+F1 will bring you back to the login screen.
  else
    echo
    cowsay -f www "That's it. Now type: enlightenment_start"
    echo
  fi
}

remov_eprog_at() {
  for I in $PROG_AT; do
    sudo make uninstall &>/dev/null
    make maintainer-clean &>/dev/null
  done
}

remov_eprog_mn() {
  for I in $PROG_MN; do
    sudo ninja -C build uninstall &>/dev/null
    rm -rf build &>/dev/null
  done
}

remov_preq() {
  if [ -d $ESRC/rlottie ]; then
    echo
    beep_question
    read -t 12 -p "Remove libiconv, libwebp and rlottie? [Y/n] " answer
    case $answer in
    [yY])
      echo
      cd $ESRC/$ICNV || exit
      sudo make uninstall &>/dev/null
      make maintainer-clean &>/dev/null
      cd .. && rm -rf $ESRC/$ICNV
      sudo rm -rf /usr/local/bin/iconv
      echo

      cd $ESRC/$LWEB || exit
      sudo make uninstall &>/dev/null
      make maintainer-clean &>/dev/null
      cd .. && rm -rf $ESRC/$LWEB
      sudo rm -rf /usr/local/bin/cwebp
      sudo rm -rf /usr/local/bin/dwebp
      echo

      cd $ESRC/rlottie || exit
      sudo ninja -C build uninstall &>/dev/null
      cd .. && rm -rf rlottie
      echo
      ;;
    [nN])
      printf "\n$ITA%s $OFF%s\n\n" "(do not remove prerequisites... OK)"
      ;;
    *)
      cd $ESRC/$ICNV || exit
      sudo make uninstall &>/dev/null
      make maintainer-clean &>/dev/null
      cd .. && rm -rf $ESRC/$ICNV
      sudo rm -rf /usr/local/bin/iconv

      cd $ESRC/$LWEB || exit
      sudo make uninstall &>/dev/null
      make maintainer-clean &>/dev/null
      cd .. && rm -rf $ESRC/$LWEB
      sudo rm -rf /usr/local/bin/cwebp
      sudo rm -rf /usr/local/bin/dwebp
      echo

      echo
      cd $ESRC/rlottie || exit
      sudo ninja -C build uninstall &>/dev/null
      cd .. && rm -rf rlottie
      echo
      ;;
    esac
  fi
}

uninstall_e24() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)

  clear
  printf "\n\n$BDR%s $OFF%s\n\n" "* UNINSTALLING ENLIGHTENMENT DESKTOP *"

  cd $HOME

  for I in $PROG_AT; do
    cd $ESRC/e24/$I && remov_eprog_at
  done

  for I in $PROG_MN; do
    cd $ESRC/e24/$I && remov_eprog_mn
  done

  cd /etc
  sudo rm -rf enlightenment

  cd /etc/xdg/menus
  sudo rm -rf e-applications.menu

  cd /usr/local
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf efl*
  sudo rm -rf eio*
  sudo rm -rf eldbus*
  sudo rm -rf elementary*
  sudo rm -rf eo*
  sudo rm -rf evas*

  cd /usr/local/bin
  sudo rm -rf eina*
  sudo rm -rf efl*
  sudo rm -rf elua*
  sudo rm -rf enventor*
  sudo rm -rf eolian*
  sudo rm -rf emotion*
  sudo rm -rf evas*
  sudo rm -rf terminology*
  sudo rm -rf ty*

  cd /usr/local/etc
  sudo rm -rf enlightenment

  cd /usr/local/include
  sudo rm -rf -- *-1
  sudo rm -rf enlightenment
  sudo rm -rf webp*

  cd /usr/local/lib
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf enventor*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf libecore*
  sudo rm -rf libector*
  sudo rm -rf libedje*
  sudo rm -rf libeet*
  sudo rm -rf libeeze*
  sudo rm -rf libefl*
  sudo rm -rf libefreet*
  sudo rm -rf libeina*
  sudo rm -rf libeio*
  sudo rm -rf libeldbus*
  sudo rm -rf libelementary*
  sudo rm -rf libelocation*
  sudo rm -rf libelput*
  sudo rm -rf libelua*
  sudo rm -rf libembryo*
  sudo rm -rf libemile*
  sudo rm -rf libemotion*
  sudo rm -rf libeo*
  sudo rm -rf libeolian*
  sudo rm -rf libephysics*
  sudo rm -rf libethumb*
  sudo rm -rf libevas*

  cd /usr/local/lib/x86_64-linux-gnu
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf ephoto*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf libecore*
  sudo rm -rf libector*
  sudo rm -rf libedje*
  sudo rm -rf libeet*
  sudo rm -rf libeeze*
  sudo rm -rf libefl*
  sudo rm -rf libefreet*
  sudo rm -rf libeina*
  sudo rm -rf libeio*
  sudo rm -rf libeldbus*
  sudo rm -rf libelementary*
  sudo rm -rf libelocation*
  sudo rm -rf libelua*
  sudo rm -rf libembryo*
  sudo rm -rf libemile*
  sudo rm -rf libemotion*
  sudo rm -rf libeo*
  sudo rm -rf libeolian*
  sudo rm -rf libethumb*
  sudo rm -rf libevas*
  sudo rm -rf libexactness*
  sudo rm -rf librlottie*
  sudo rm -rf rage*

  cd /usr/local/lib/x86_64-linux-gnu/cmake
  sudo rm -rf Ecore*
  sudo rm -rf Edje*
  sudo rm -rf Eet*
  sudo rm -rf Eeze*
  sudo rm -rf Efl*
  sudo rm -rf Efreet
  sudo rm -rf Eina*
  sudo rm -rf Eio*
  sudo rm -rf Eldbus*
  sudo rm -rf Elementary*
  sudo rm -rf Elua*
  sudo rm -rf Emile*
  sudo rm -rf Emotion*
  sudo rm -rf Eo*
  sudo rm -rf Eolian*
  sudo rm -rf Emile*
  sudo rm -rf Ethumb*
  sudo rm -rf Evas*

  cd /usr/local/lib/x86_64-linux-gnu/pkgconfig
  sudo rm -rf ecore*
  sudo rm -rf ector*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf eina*
  sudo rm -rf eio*
  sudo rm -rf eldbus*
  sudo rm -rf elementary*
  sudo rm -rf elocation*
  sudo rm -rf elua*
  sudo rm -rf embryo*
  sudo rm -rf emile*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf enventor*
  sudo rm -rf evisum*
  sudo rm -rf eo*
  sudo rm -rf eolian*
  sudo rm -rf ephoto*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf everything*
  sudo rm -rf exactness*
  sudo rm -rf rage*
  sudo rm -rf rlottie*
  sudo rm -rf terminology*

  cd /usr/local/man/man1
  sudo rm -rf terminology*
  sudo rm -rf ty*

  cd /usr/local/share
  sudo rm -rf dbus*
  sudo rm -rf ecore*
  sudo rm -rf edje*
  sudo rm -rf eeze*
  sudo rm -rf efl*
  sudo rm -rf efreet*
  sudo rm -rf elementary*
  sudo rm -rf elua*
  sudo rm -rf embryo*
  sudo rm -rf emotion*
  sudo rm -rf enlightenment*
  sudo rm -rf enventor*
  sudo rm -rf evisum*
  sudo rm -rf eo*
  sudo rm -rf eolian*
  sudo rm -rf ephoto*
  sudo rm -rf ethumb*
  sudo rm -rf evas*
  sudo rm -rf exactness*
  sudo rm -rf rage*
  sudo rm -rf terminology*
  sudo rm -rf wayland-sessions*

  cd /usr/local/share/applications
  sudo sed -i '/enlightenment_filemanager/d' mimeinfo.cache
  sudo sed -i '/ephoto/d' mimeinfo.cache
  sudo sed -i '/rage/d' mimeinfo.cache
  sudo rm -rf terminology.desktop

  cd /usr/local/share/icons
  sudo rm -rf Enlightenment*
  sudo rm -rf elementary*
  sudo rm -rf terminology*

  cd /usr/local/share/icons/hicolor/128x128/apps
  sudo rm -rf evisum.png
  sudo rm -rf terminology.png

  cd /usr/share/dbus-1/services
  sudo rm -rf org.enlightenment.Ethumb.service

  cd /usr/share/wayland-sessions
  sudo rm -rf enlightenment.desktop

  cd /usr/share/xsessions
  sudo rm -rf enlightenment.desktop

  cd $HOME
  rm -rf $ESRC/e24
  rm -rf $SCRFLR
  rm -rf .e
  rm -rf .elementary
  rm -rf .cache/ebuilds
  rm -rf .cache/efreet
  rm -rf .cache/ephoto
  rm -rf .cache/evas_gl_common_caches
  rm -rf .cache/rage
  rm -rf .config/enventor
  rm -rf .config/ephoto
  rm -rf .config/evisum
  rm -rf .config/rage
  rm -rf .config/terminology

  remov_preq

  if [ -d $HOME/.ccache ]; then
    echo
    beep_question
    read -t 12 -p "Remove the ccache folder? [y/N] " answer
    case $answer in
    [yY])
      ccache -C
      rm -rf $HOME/.ccache
      ;;
    [nN])
      printf "\n$ITA%s $OFF%s\n\n" "(do not delete the ccache folder... OK)"
      ;;
    *)
      printf "\n$ITA%s $OFF%s\n\n" "(do not delete the ccache folder... OK)"
      ;;
    esac
  fi

  if [ -f $HOME/.bash_aliases ]; then
    echo
    beep_question
    read -t 12 -p "Remove the bash_aliases file? [Y/n] " answer
    case $answer in
    [yY])
      rm -rf $HOME/.bash_aliases && source $HOME/.bashrc
      sleep 1
      ;;
    [nN])
      printf "\n$ITA%s $OFF%s\n\n" "(do not delete bash_aliases... OK)"
      sleep 1
      ;;
    *)
      echo
      rm -rf $HOME/.bash_aliases && source $HOME/.bashrc
      sleep 1
      ;;
    esac
  fi

  find /usr/local/share/locale/*/LC_MESSAGES 2>/dev/null | while read -r I; do
    echo "$I" |
      xargs sudo rm -rf $(grep -E 'efl|enlightenment|enventor|ephoto|evisum|libiconv|terminology')
  done

  sudo rm -rf /usr/lib/libintl.so
  sudo ldconfig
  sudo updatedb
  echo
}

main() {
  trap '{ printf "\n$BDR%s $OFF%s\n\n" "KEYBOARD INTERRUPT."; exit 130; }' INT

  INPUT=0
  printf "\n$BLD%s $OFF%s\n" "Please enter the number of your choice:"
  sel_menu

  if [ $INPUT == 1 ]; then
    do_tests
    install_now
  elif [ $INPUT == 2 ]; then
    do_tests
    update_go
  elif [ $INPUT == 3 ]; then
    do_tests
    release_go
  elif [ $INPUT == 4 ]; then
    do_tests
    wld_go
  elif [ $INPUT == 5 ]; then
    uninstall_e24
  else
    beep_exit
    exit 1
  fi
}

main
