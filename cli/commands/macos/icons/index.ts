import { join } from "path";
import jimp from "jimp";
import { config } from "../../../config";
import { Logger } from "../../../logger";

const logger = new Logger("macos:icons");
const sizes: number[] = [16, 32, 64, 128, 256, 512, 1024];

export const generate = async () => {
    logger.log(`Icon path: r{clr,cyanBright,${config.macos.icon}}.`);
    const original = await jimp.read(config.macos.icon);

    for (const size of sizes) {
        const path = join(
            config.macos.project,
            `/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_${size}.png`
        );

        const img = original.clone();
        img.quality(100);
        img.resize(size, size);
        await img.writeAsync(path);
        logger.log(`Generated: r{clr,cyanBright,${path}}.`);
    }
};
