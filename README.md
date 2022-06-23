# heimdall-osx-arm64

[Heimdall](https://www.glassechidna.com.au/heimdall) specifically built for ARM64 macOS.

I made this initially only as a reference for myself in the future
because I couldn't find any prebuilt binary for ARM64 macOS,
also I had a hard time building Heimdall on my M1 MacBook Pro.

# Downloads

Download from [Releases section](https://github.com/fathonix/heimdall-osx-arm64/releases/latest).

Even if you download a prebuilt binary, **you still have to install [Homebrew](https://brew.sh) and its dependencies.**
(except `cmake` which is only required for building).
More details can be seen below.

# Installing

To install Homebrew, run this command:

    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Install libusb and Qt5 through Homebrew.

    brew install libusb qt@5

After downloading `heimdall` binary, move it to `/usr/local/bin`.

You can move it by issuing this command:

    sudo mv /path/to/heimdall /usr/local/bin/

Extract `heimdall-frontend-x.x.x.zip` and put `heimdall-frontend.app` in `/Applications`.

Before using `heimdall-frontend`, you have to set user-scope `PATH` to make sure it detects the `heimdall` binary.
Run the below command to set the `PATH`.

    sudo launchctl config user path "/usr/local/bin:$PATH"

# Building

Make sure you already have Homebrew and Xcode Command-Line Tools installed to simplify the process of getting the dependencies and building.

To install Xcode Command-Line Tools, run this command:

    xcode-select --install

Install CMake, libusb and Qt5 through Homebrew.

    brew install cmake libusb qt@5

The original Heimdall hasn't been updated since 2017,
and Samsung has updated Odin protocol on their latest devices, which broke the original Heimdall.
Moreover, the original Heimdall can't be compiled with Apple Clang anymore.
After lots of trials and errors in trying different versions and forks,
I found [Henrik Grimler](https://github.com/Grimler91) fork works best.
It's also still actively maintained.

Clone the repo to get the source code.

    git clone https://git.sr.ht/~grimler/Heimdall

Change to the repo directory.

    cd Heimdall

Switch to the latest stable version.
At the time of writing, the latest stable version is v2.0.1.
You can check by running `git tag`.

    git checkout tags/v2.0.1

Run `cmake` to configure things.

    cmake . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DQt5Widgets_DIR=/opt/homebrew/opt/qt5/lib/cmake/Qt5Widgets

Export `LIBRARY_PATH` environment variable pointing to Homebrew `lib` folder, to avoid linking issues.

    export LIBRARY_PATH=/opt/homebrew/lib

Finally, run `make` to build and install.

    make
    sudo make install

You'll see that `heimdall` is now installed in `/usr/local/bin` and `heimdall-frontend` in `/Applications`.

To check that everything works, run `heimdall`.

    heimdall info

It should output like this:

    Heimdall v2.0.1

    Copyright (c) 2010-2017 Benjamin Dobell, Glass Echidna
    https://www.glassechidna.com.au/

    This software is provided free of charge. Copying and redistribution is encouraged.

    If you appreciate this software and you would like to support future development please consider donating:
    https://www.glassechidna.com.au/donate/

    Heimdall utilises libusb for all USB communication:
        https://www.libusb.info/

    libusb is licensed under the LGPL-2.1:
        https://www.gnu.org/licenses/licenses.html#LGPL

In the other hand, `heimdall-frontend` should run, but it can't find `heimdall` binary.
If you click **Detect** in **Utilities** tab, you will see this output.

    FRONTEND ERROR: Failed to start Heimdall!

That's because it's located in `/usr/local/bin` which is not in user-scope `PATH`.

Run this command to add the directory to `PATH`.

    sudo launchctl config user path "/usr/local/bin:$PATH"

Reboot your Mac. Now you should see the following output once you click Detect.

    ERROR: Failed to detect compatible download-mode device.

Or this if you've connected your phone.

    Device detected

# Building without Frontend

If you don't want to use `heimdall-frontend`,
or you want to use another frontend like [JOdin3](https://github.com/GameTheory-/jodin3),
you can just build the `heimdall` binary.

Do all steps in [Building section](#building), with some changes.

You don't need to install Qt5, as it's only needed by `heimdall-frontend`.

    brew install cmake libusb

Remove `Qt5Widgets_DIR` and append `DISABLE_FRONTEND` option in `cmake`.

    cmake . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DDISABLE_FRONTEND=ON

Once you've done everything, you'll only get `heimdall` binary located in `/usr/local/bin`.

# Notes

* This binary does not have built-in libraries; instead it relies on libraries provided by Homebrew. Because of that, **you must not uninstall Homebrew, libusb and Qt5.** (if you use `heimdall-frontend`) **Otherwise the binary would crash.**

  I'm still thinking about building `heimdall` statically and bundling Qt5 to `heimdall-frontend`, but I haven't found a way to do it.

* Although Heimdall repository provides a "driver" for macOS, I don't think you'll need it. I haven't got any problems so far, apart from some warnings which are fine for now. You can't even use the driver without disabling SIP or [System Integrity Protection](https://support.apple.com/en-us/HT204899) which will [prevent you from running iOS apps until you enable it](https://forums.macrumors.com/threads/if-you-disable-sip-all-you-ios-apps-will-stop-working-on-your-m1.2269661/).

* For those who don't know yet, **you can only do one read-write operation on Heimdall at one session**, unlike Odin. For example, if you've run `heimdall flash --no-reboot` or `heimdall print-pit --no-reboot` once, the second time would fail with errors like `ERROR: Protocol initialisation failed!`. See this [issue](https://github.com/Benjamin-Dobell/Heimdall/issues/413#issuecomment-336619935).

  If you want to run another operation, reboot your phone to Download Mode again.

Many thanks to:

* [Glass Echidna](https://www.glassechidna.com.au) for developing Heimdall in the first place
* [Henrik Grimler](https://github.com/Grimler91) for maintaining Heimdall to support newer devices
* [Arch Linux heimdall Package Details](https://archlinux.org/packages/community/x86_64/heimdall/) (I found how to build Heimdall from this because instructions from Heimdall itself don't work)
* [heimdall-nogui-git AUR](https://aur.archlinux.org/packages/heimdall-nogui-git) for commands to build Heimdall without Frontend
