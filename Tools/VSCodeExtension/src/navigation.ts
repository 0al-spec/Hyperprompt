import * as path from 'path';

export type LinkAtParams = {
	filePath: string;
	line: number;
	column: number;
};

export type LinkSpanResponse = {
	literal: string;
	byteRangeStart: number;
	byteRangeEnd: number;
	lineRangeStart: number;
	lineRangeEnd: number;
	columnRangeStart: number;
	columnRangeEnd: number;
	referenceHint: string;
	sourceFile: string;
};

export type ResolveParams = {
	linkPath: string;
	sourceFile: string;
	workspaceRoot: string;
};

export type ResolvedTarget = {
	type: 'inlineText' | 'markdownFile' | 'hypercodeFile' | 'forbidden' | 'invalid' | 'ambiguous';
	path?: string;
	fileExtension?: string;
	reason?: string;
	candidates?: string[];
};

export type NavigationRequest = (method: string, params: unknown, timeoutMs: number) => Promise<unknown>;

export const buildLinkAtParams = (filePath: string, zeroBasedLine: number, zeroBasedColumn: number): LinkAtParams => {
	return {
		filePath,
		line: zeroBasedLine + 1,
		column: zeroBasedColumn + 1
	};
};

export const buildResolveParams = (linkPath: string, sourceFile: string, workspaceRoot?: string): ResolveParams => {
	return {
		linkPath,
		sourceFile,
		workspaceRoot: workspaceRoot ?? path.dirname(sourceFile)
	};
};

export const runLinkAtRequest = async (
	request: NavigationRequest,
	params: LinkAtParams,
	timeoutMs: number
): Promise<LinkSpanResponse | null> => {
	const result = await request('editor.linkAt', params, timeoutMs);
	return result as LinkSpanResponse | null;
};

export const runResolveRequest = async (
	request: NavigationRequest,
	params: ResolveParams,
	timeoutMs: number
): Promise<ResolvedTarget> => {
	const result = await request('editor.resolve', params, timeoutMs);
	return result as ResolvedTarget;
};

export const resolvedTargetPath = (target: ResolvedTarget | null): string | null => {
	if (!target) {
		return null;
	}
	if (target.type === 'markdownFile' || target.type === 'hypercodeFile') {
		return target.path ?? null;
	}
	return null;
};

export const describeResolvedTarget = (target: ResolvedTarget | null): string => {
	if (!target) {
		return 'No link resolved at this position.';
	}

	switch (target.type) {
		case 'markdownFile':
			return `Markdown file: ${target.path ?? 'Unknown path'}`;
		case 'hypercodeFile':
			return `Hypercode file: ${target.path ?? 'Unknown path'}`;
		case 'inlineText':
			return 'Inline text (not a file reference).';
		case 'forbidden':
			return `Forbidden extension: .${target.fileExtension ?? 'unknown'}`;
		case 'invalid':
			return `Invalid link: ${target.reason ?? 'Unknown reason'}`;
		case 'ambiguous':
			return `Ambiguous link: ${(target.candidates ?? []).join(', ') || 'No candidates'}`;
		default:
			return 'Unrecognized link target.';
	}
};
