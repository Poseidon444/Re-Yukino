import { join } from "path";
import { writeFile } from "fs-extra";
import ejs from "ejs";
import { spawn, promisifyChildProcess } from "../../../../spawn";
import { getVersion } from "../../../../helpers/version";
import { path as iconPath } from "../../../../icons/windows";
import { Logger } from "../../../../logger";
import { config } from "../../../../config";
import { buildDir } from "../";

const logger = new Logger("build:windows:installer");

const installerIss = join(__dirname, "installer.iss");
const installerGIss = join(__dirname, "installer.g.iss");

export const build = async () => {
    const version = await getVersion();

    const context: Record<string, string> = {
        rootDir: buildDir,
        primaryExe: "yukino_app.exe",
        outputDir: config.windows.packed,
        setupName: `${config.name} v${version} Setup`,
        appName: config.name,
        version: version,
        url: config.url,
        appIcon: iconPath,
    };

    const rendered = await ejs.renderFile(installerIss, context, {
        openDelimiter: "{",
        closeDelimiter: "}",
        delimiter: "%",
    });
    await writeFile(installerGIss, rendered);
    logger.log(`Rendered ${installerIss}`);

    await promisifyChildProcess(await spawn("iscc ", [installerGIss], config.base));
    logger.log(`Installer created: ${join(context.outputDir, `${context.setupName}.exe`)}`);
}