import { join } from "path";
import { spawn } from "../../../spawn";
import { config } from "../../../config";
import { Logger } from "../../../logger";

export const buildDir = join(config.base, "build/macos/Build/Products/Release");

const logger = new Logger("macos:build");

export const build = async () => {
    logger.log("Running build command...");
    await spawn("flutter", ["build", "macos"], { cwd: config.base });
    logger.log("Finished running build command.");

    logger.log(`Binaries generated: r{clr,cyanBright,${buildDir}}.`);
};
