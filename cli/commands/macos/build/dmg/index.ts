import { dirname, join } from "path";
import { ensureDir, readFile, writeFile, rename } from "fs-extra";
import * as png2icons from "png2icons";
import { spawn } from "../../../../spawn";
import { getVersion } from "../../../version/print";
import { Logger } from "../../../../logger";
import { config } from "../../../../config";
import { buildDir } from "../";

const icns = join(config.base, "build/macos/icon.icns");

const logger = new Logger("macos:build:dmg");

export const build = async () => {
    const version = await getVersion();

    await ensureDir(dirname(icns));
    await writeFile(
        icns,
        png2icons.createICNS(
            await readFile(config.macos.icon),
            png2icons.BEZIER,
            256
        )
    );
    logger.log(`Generated: r{clr,cyanBright,${icns}}.`);

    const outName = `${config.name}_v${version}-macos.dmg`;
    await spawn(
        "create-dmg",
        [
            "--volname",
            `"${config.code}"`,
            "--volicon",
            `"${icns}"`,
            // "--background",
            // `"installer_background.jpg"`,
            "--window-pos",
            "200",
            "120",
            "--window-size",
            "800",
            "529",
            "--icon-size",
            "130",
            "--text-size",
            "14",
            "--icon",
            `"${config.name}.app"`,
            "260",
            "260",
            "--hide-extension",
            `"${config.name}.app"`,
            "--app-drop-link 540 250",
            "--hdiutil-quiet",
            `"${outName}"`,
            `"${config.name}.app"`,
        ],
        { cwd: buildDir }
    );

    const finalPath = join(config.macos.packed, outName);
    await ensureDir(dirname(finalPath));
    await rename(join(buildDir, outName), finalPath);
    logger.log(`Dmg created: r{clr,cyanBright,${finalPath}}.`);
};
