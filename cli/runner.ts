import chalk from "chalk";
import prettyMs from "pretty-ms";
import { executeHooksFor } from "./hooks";
import { Logger } from "./logger";

export const run = async (fn: () => Promise<void>) => {
    const startedAt = Date.now();
    try {
        if (!process.env.npm_lifecycle_event) {
            throw new Error("Command must be triggered using npm scripts");
        }

        await executeHooksFor("prerun", process.env.npm_lifecycle_event);
        await fn();
        await executeHooksFor("postrun", process.env.npm_lifecycle_event);

        console.log(
            Logger.renderText(
                `\nr{sym,success} Finished in r{clr,greenBright,${prettyMs(
                    Date.now() - startedAt
                )}}\n`
            )
        );
    } catch (err) {
        console.error(chalk.redBright(err));

        if (err instanceof Error && err.stack) {
            console.error(chalk.gray(err.stack.replace(err.message, "")));
        }

        console.log(
            Logger.renderText(
                `\nr{sym,error} Failed in r{clr,redBright,${prettyMs(
                    Date.now() - startedAt
                )}}\n`
            )
        );
        process.exit(1);
    }
};
