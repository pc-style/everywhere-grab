import { afterEach, describe, expect, it } from "vite-plus/test";
import { getPackagesToInstall, resolveGrabPackageSpec } from "../src/utils/install.js";

describe("getPackagesToInstall", () => {
  afterEach(() => {
    delete process.env.GRAB_PKG;
  });

  it("should return react-grab when includeReactGrab is true", () => {
    const packages = getPackagesToInstall(true);

    expect(packages).toEqual(["react-grab"]);
  });

  it("should return empty array when includeReactGrab is false", () => {
    const packages = getPackagesToInstall(false);

    expect(packages).toEqual([]);
  });

  it("should use an explicit package spec", () => {
    const packages = getPackagesToInstall(true, "file:/fork/packages/react-grab");

    expect(packages).toEqual(["file:/fork/packages/react-grab"]);
  });

  it("should prefer explicit spec over GRAB_PKG", () => {
    process.env.GRAB_PKG = "file:/from-env";
    const packages = getPackagesToInstall(true, "file:/from-flag");

    expect(packages).toEqual(["file:/from-flag"]);
  });

  it("should use GRAB_PKG when no explicit spec is passed", () => {
    process.env.GRAB_PKG = "file:/from-env";
    const packages = getPackagesToInstall(true);

    expect(packages).toEqual(["file:/from-env"]);
  });
});

describe("resolveGrabPackageSpec", () => {
  afterEach(() => {
    delete process.env.GRAB_PKG;
  });

  it("should default to react-grab", () => {
    expect(resolveGrabPackageSpec()).toBe("react-grab");
  });
});
