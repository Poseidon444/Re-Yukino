import { join } from "path";
import { promisify } from "util";
import Zip from "adm-zip";
import { getVersion } from "../../../version/print";
import { Logger } from "../../../../logger";
import { config } from "../../../../config";
import { buildDir } from "../";

const logger = new Logger("windows:build:zip");

export const zip = async () => {
    const version = await getVersion();
    const out = join(
        config.windows.packed,
        `${config.name}_v${version}-windows.zip`
    );

    const file = new Zip();
    file.addLocalFolder(buildDir);
    await promisify(file.writeZip)(out);

    logger.log(`Zip created: r{clr,cyanBright,${out}}.`);
};
