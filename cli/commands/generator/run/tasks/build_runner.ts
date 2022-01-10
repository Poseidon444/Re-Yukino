import { dirname, join, relative } from "path";
import {
    pathExists,
    copyFile,
    rm,
    ensureDir,
    readFile,
    writeFile,
} from "fs-extra";
import { SpawnError, spawn, isForce } from "../../../../spawn";
import { config } from "../../../../config";
import { Logger } from "../../../../logger";

const logger = new Logger("generator:run:build_runner");

const generated = {
    from: join(config.base, "lib"),
    to: join(config.base, "lib/modules/database/objectbox"),
    pre: {
        files: ["objectbox-model.json"],
        async do() {
            logger.log(
                `Restoring files to r{clr,cyanBright,${relative(
                    config.base,
                    generated.from
                )}}.`
            );

            for (const x of generated.pre.files) {
                const path = join(generated.to, x);
                if (await pathExists(path)) {
                    await copyFile(path, join(generated.from, x));
                }
            }
        },
    },
    post: {
        files: ["objectbox.g.dart", "objectbox-model.json"],
        async do(success: boolean) {
            logger.log(
                `Moving files to r{clr,cyanBright,${relative(
                    config.base,
                    generated.to
                )}}.`
            );

            await ensureDir(generated.to);

            for (const x of generated.post.files) {
                const path = join(generated.from, x);

                if (success) {
                    if (/\.g\.dart$/.test(x)) {
                        await writeFile(
                            path,
                            await generated.modifyImports(path, generated.to)
                        );
                    }

                    await copyFile(path, join(generated.to, x));
                }

                if (await pathExists(path)) {
                    await rm(path, {
                        recursive: true,
                        force: true,
                    });
                }
            }
        },
    },
    async modifyImports(path: string, to: string) {
        const from = dirname(path);
        const content = (await readFile(path)).toString();

        const importRegex = /import ['"](?!dart|package:)(.*)['"];/;
        const modified = content.replace(RegExp(importRegex, "g"), (str) => {
            const match = str.match(importRegex)!;
            const importFromPath = join(from, match[1]);
            const importToPath = relative(to, importFromPath).replace(
                /\\/g,
                "/"
            );

            return `import '${importToPath}';`;
        });

        return modified;
    },
};

const execute = async (force: boolean) => {
    try {
        await generated.pre.do();

        const flags: string[] = [];

        if (force) {
            flags.push("--delete-conflicting-outputs");
        }

        await spawn(
            "flutter",
            ["packages", "pub", "run", "build_runner", "build", ...flags],
            { cwd: config.base }
        );

        await generated.post.do(true);
    } catch (err) {
        await generated.post.do(false);
        throw err;
    }
};

export const runDartBuildRunner = async () => {
    logger.log("Running r{clr,cyanBright,dart build_runner} command...");

    try {
        await execute(isForce());
    } catch (err: any) {
        if (
            err instanceof SpawnError &&
            typeof err.result.code === "number" &&
            err.result.code === 78
        ) {
            logger.warn(
                `Found conflicting outputs, retrying with r{clr,redBright,--delete-conflicting-outputs} flag`
            );

            await execute(true);
        } else {
            throw err;
        }
    }

    logger.log("Finished running r{clr,cyanBright,dart build_runner} command.");
};
