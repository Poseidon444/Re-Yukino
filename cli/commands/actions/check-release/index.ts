import { Octokit } from "@octokit/rest";
import { RequestError } from "@octokit/request-error";
import { config } from "../../../config";
import { Logger } from "../../../logger";
import { getArgs } from "../../../spawn";
import { getVersion } from "../../version/print";

const logger = new Logger("actions:check-release");

export const checkRelease = async () => {
    logger.log("Checking for previous releases...");

    const ends = getArgs().map((x) => {
        let y: string = x;
        if (y.startsWith("'")) y = y.slice(1);
        if (y.endsWith("'")) y = y.slice(0, -1);
        return y;
    });

    if (!Array.isArray(ends) || !ends.length) {
        throw new Error("No inputs were got");
    }

    logger.log(
        `Input: r{clr,cyanBright,${ends.map((x) => `"${x}"`).join(", ")}}.`
    );

    const octokit = new Octokit();
    const version = await getVersion();

    const res = await octokit
        .request("GET /repos/{owner}/{repo}/releases/tags/{tag}", {
            owner: config.github.username,
            repo: config.github.repo,
            tag: `v${version}`,
        })
        .catch((err) => {
            if (err instanceof RequestError && err.status == 404) {
                return null;
            }

            throw err;
        });

    if (res?.status == 200) {
        const matches = res.data.assets.some((x: any) =>
            ends.some((y: string) => x.name.endsWith(y))
        );

        if (matches) {
            throw new Error(
                `Matches in tag r{clr,cyanBright,v${version}} were found. Please remove them before building.`
            );
        }
    }

    logger.log(
        `Tag r{clr,cyanBright,v${version}} does not exist, proceeding...`
    );
};
