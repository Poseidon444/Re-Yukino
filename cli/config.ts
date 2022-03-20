import { resolve, join } from "path";

const pkgJson = require("../package.json");

const root = resolve(__dirname, "..");

const defaultIcon = join(root, "assets/images/yukino-icon.png");
const buildDir = join(root, "build", "packed");
const cacheDir = join(__dirname, ".cache");

const githubMatch = /^git\+https:\/\/github\.com\/([^/]+)\/([^.]+)\.git$/.exec(
    pkgJson.repository.url
);

export const config = {
    name: "Yukino",
    code: "yukino_app",
    url: "https://yukino-org.github.io",
    base: root,
    cacheDir: cacheDir,
    android: {
        project: join(root, "android"),
        icon: defaultIcon,
        packed: join(buildDir, "android"),
    },
    ios: {
        project: join(root, "ios"),
        icon: defaultIcon,
        packed: join(buildDir, "ios"),
    },
    macos: {
        project: join(root, "macos"),
        icon: defaultIcon,
        packed: join(buildDir, "macos"),
    },
    linux: {
        project: join(root, "linux"),
        icon: defaultIcon,
        packed: join(buildDir, "linux"),
    },
    windows: {
        project: join(root, "windows"),
        icon: defaultIcon,
        packed: join(buildDir, "windows"),
    },
    github: {
        username: githubMatch![1],
        repo: githubMatch![2],
    },
};
