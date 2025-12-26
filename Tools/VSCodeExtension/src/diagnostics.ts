export type DiagnosticSeverity = 'error' | 'warning' | 'info' | 'hint';

export type SourcePosition = {
	line: number;
	column: number;
};

export type SourceRange = {
	start: SourcePosition;
	end: SourcePosition;
};

export type RpcDiagnostic = {
	code: string;
	severity: DiagnosticSeverity;
	message: string;
	range?: SourceRange;
};

const severityValues = new Set<DiagnosticSeverity>(['error', 'warning', 'info', 'hint']);

export const normalizeSeverity = (severity: string | undefined): DiagnosticSeverity => {
	if (severity && severityValues.has(severity as DiagnosticSeverity)) {
		return severity as DiagnosticSeverity;
	}
	return 'error';
};

export const toZeroBasedPosition = (position: SourcePosition) => {
	return {
		line: Math.max(0, position.line - 1),
		character: Math.max(0, position.column - 1)
	};
};

export const toZeroBasedRange = (range?: SourceRange) => {
	if (!range) {
		return null;
	}
	return {
		start: toZeroBasedPosition(range.start),
		end: toZeroBasedPosition(range.end)
	};
};
