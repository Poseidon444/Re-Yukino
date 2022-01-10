import { dirname, join, relative } from "path";
import { ensureDir, readdir, readFile, rename, writeFile } from "fs-extra";
import { spawn } from "../../../../spawn";
import { getVersion } from "../../../version/print";
import { Logger } from "../../../../logger";
import { config } from "../../../../config";
import { buildDir } from "../";

const logger = new Logger("linux:build:appimage");

const builderYml = join(__dirname, "builder.yml");
const builderGYml = join(__dirname, "builder.g.yml");

export const build = async () => {
    const version = await getVersion();

    const context: Record<string, string> = {
        rootDir: `./${relative(config.base, buildDir)}`,
        primaryExe: config.code,
        appName: config.name,
        version: version,
    };

    const template = (await readFile(builderYml)).toString();
    const rendered = template.replace(/{{{.*?}}}/g, (match) => {
        const key = match.slice(3, -3).trim();
        return context[key];
    });

    await writeFile(builderGYml, rendered);
    logger.log(`Rendered r{clr,cyanBright,${builderGYml}}.`);

    logger.log("Running r{clr,cyanBright,appimage-builder} command...");
    await spawn(
        "appimage-builder",
        ["--recipe", `./${relative(config.base, builderGYml)}`, "--skip-tests"],
        { cwd: config.base, stdio: "inherit" }
    );
    logger.log("Finished running r{clr,cyanBright,appimage-builder} command.");

    const outPath = (await readdir(config.base)).find((x) =>
        x.endsWith(".AppImage")
    );
    if (!outPath) {
        throw new Error("Failed to find generated appimage");
    }

    const finalPath = join(
        config.linux.packed,
        `${config.name}_v${version}-linux.AppImage`
    );
    await ensureDir(dirname(finalPath));
    await rename(outPath, finalPath);
    logger.log(`AppImage created: r{clr,cyanBright,${finalPath}}.`);
};
