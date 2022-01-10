import { config } from "../config";
import { Logger } from "../logger";
import { spawn } from "../spawn";

const hooks: HooksConfig[] = require("./hooks.json");

export const HookTypes = ["prerun", "postrun"] as const;
export type HookType = typeof HookTypes[number];

export interface HooksConfig {
    type: HookType;
    triggers: string[];
    commands: string[];
}

export const executeHook = async (hook: HooksConfig) => {
    for (const cmd of hook.commands) {
        await spawn("npm", ["run", cmd, "-s"], {
            cwd: config.base,
            stdio: "inherit",
        });
    }
};

export const executeHooksFor = async (type: HookType, cmd: string) => {
    const logger = new Logger(`${cmd}:hooks`);
    logger.log(`Executing hook: r{clr,cyanBright,${type}}...`);

    let cycles = 0;
    for (const hook of hooks) {
        if (hook.type === type && hook.triggers.includes(cmd)) {
            await executeHook(hook);
            cycles += 1;
        }
    }

    logger.log(
        `Hook finished: r{clr,cyanBright,${type}} with r{clr,cyanBright,${cycles}} commands.`
    );
};
