# howitseesus
Repository containing the source code for How it sees us.

This interactive installation scans, deconstructs and reconstrucs your moving body. Creating its own digital representation of you.

## Installation guide
In order to install and run the program, the following prerequisites are needed:

- Processing (verified to work at v3.5.4)


### Processing prerequisites

The program requires the following packages to work:

- ControlP5, available from the processing library
- HE_Mesh, available from the processing library
- Ani, available from the processing library
- oscP5, available from the processing library
- Spout for Processing, available from the processing library

- SimpleOpenNI, available [via github](https://github.com/totovr/SimpleOpenNI)

    - make sure to use out the branch that is nearest to your processing version
    - after downloading, extract the **SimpleOpenNI** folder inside your download folder and move it to the processing libraries folder. [(more info)](https://stackoverflow.com/questions/43004770/how-to-add-external-libraries-in-processing)

### Orbbec setup

We use `SimpleOpenNI` to interface with the Orbbec Astra, in order to allow the processing project to read data from the camera, we have to use the following steps:

1. Download and install the Orbbec drivers for windows from the  [orbbec downloads page](https://orbbec3d.com/develop/).
2. Download the Astra SDK [orbbec downloads page](https://orbbec3d.com/develop/).
3. Find the orbbec.dll and orbbec.ini files under `\bin` and copy them into the `library\win64\OpenNI2\Drivers` folder.
4. Sanity check, reboot your machine.

### Sketch setup
TODO: write documentation on configuration of sketch variables etc.a

