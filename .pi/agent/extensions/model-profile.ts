import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const profiles = {
	"codex-cheap": { provider: "openai-codex", model: "gpt-6-luna" },
	"opencode-go": { provider: "opencode-go", model: "gpt-6-luna" },
} as const;

export default function modelProfile(pi: ExtensionAPI) {
	let startupError: string | undefined;
	pi.on("input", (_event, ctx) => {
		if (!startupError) return;
		ctx.ui.notify(startupError, "error");
		return { action: "handled" };
	});
	pi.on("before_agent_start", (_event, ctx) => {
		if (startupError) ctx.abort();
	});
	pi.registerFlag("profile", {
		type: "string",
		description: "Model/agent profile: codex-cheap or opencode-go (shared Pi sessions)",
	});

	pi.on("session_start", async (_event, ctx) => {
		startupError = undefined;
		const name = pi.getFlag("profile");
		if (name === undefined) return;
		const fail = (message: string) => {
			startupError = message;
			ctx.ui.notify(message, "error");
			if (ctx.mode === "print") {
				process.stderr.write(`${message}\n`);
				process.exitCode = 1;
			}
			ctx.shutdown();
		};
		if (name !== "codex-cheap" && name !== "opencode-go") {
			fail(`Unknown Pi profile: ${String(name)}. Choose codex-cheap or opencode-go.`);
			return;
		}
		const profile = profiles[name];
		const model = ctx.modelRegistry.find(profile.provider, profile.model);
		if (!model) {
			fail(`Profile ${name}: missing model ${profile.provider}/${profile.model}.`);
			return;
		}
		if (!(await pi.setModel(model))) {
			fail(`Profile ${name}: authentication unavailable for ${profile.provider}. Configure its credentials first.`);
			return;
		}
		pi.setThinkingLevel("max");
		if (pi.getThinkingLevel() !== "max") {
			fail(`Profile ${name}: the model does not support max thinking; refusing a silent downgrade.`);
			return;
		}
		ctx.ui.setStatus("model-profile", `profile: ${name}`);
	});
}
