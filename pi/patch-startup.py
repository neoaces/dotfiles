#!/usr/bin/env python3
"""Patch pi's startup screen (re-run after `pi update`; idempotent).

- Removes the "Pi can explain its own features..." onboarding line.
- Removes the "Press ctrl+o to show full startup help" hint.
- Shows loaded extensions on a single line: "[Extensions] a, b, c".
"""
import glob
import os

root = os.path.expanduser("~/.pi/agent/install")
version = open(f"{root}/current-version").read().strip()
pkg = f"{root}/releases/{version}/node_modules/@earendil-works/pi-coding-agent/dist"

PATCHES = [
    # header: drop onboarding line (compact + expanded variants)
    ("${compactOnboarding()}\n\n${onboarding()}`", "${compactOnboarding()}`"),
    ("${withLogo(expandedInstructions())}\n\n${onboarding()}`", "${withLogo(expandedInstructions())}`"),
    # header: drop "Press ctrl+o to show full startup help" hint (must follow onboarding patch)
    ("${withLogo(compactInstructions())}\n${compactOnboarding()}`", "${withLogo(compactInstructions())}`"),
    # extensions: header and names on one line, regardless of expansion
    (
        'addLoadedSection("Extensions",()=>formatCompactList(extensionLabels),extList,"mdHeading")',
        'this.loadedResourcesContainer.addChild(new ThemedText(()=>`${sectionHeader("Extensions")} ${theme.fg("dim",[...extensionLabels].sort((a,b)=>a.localeCompare(b)).join(", "))}`,0,0)),this.loadedResourcesContainer.addChild(new Spacer(1))',
    ),
    # unbundled dist (used by SDK imports)
    ("${compactOnboarding()}\\n\\n${onboarding()}`", "${compactOnboarding()}`"),
    ("${withLogo(expandedInstructions())}\\n\\n${onboarding()}`", "${withLogo(expandedInstructions())}`"),
    ("${withLogo(compactInstructions())}\\n${compactOnboarding()}`", "${withLogo(compactInstructions())}`"),
    (
        'addLoadedSection("Extensions", extensionCompactList, extList, "mdHeading");',
        'this.loadedResourcesContainer.addChild(new ThemedText(() => `${sectionHeader("Extensions")} ${theme.fg("dim", [...extensionLabels].sort((a, b) => a.localeCompare(b)).join(", "))}`, 0, 0));\n                this.loadedResourcesContainer.addChild(new Spacer(1));',
    ),
]

files = glob.glob(f"{pkg}/bundle/**/*.js", recursive=True) + [f"{pkg}/modes/interactive/interactive-mode.js"]
hits = 0
for path in files:
    s = open(path).read()
    new = s
    for old, rep in PATCHES:
        new = new.replace(old, rep)
    if new != s:
        open(path, "w").write(new)
        hits += 1
        print("patched", path)
print(f"pi {version}: {hits} file(s) patched" if hits else f"pi {version}: already patched (or patterns changed)")
