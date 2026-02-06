import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class RequirePublicDocsRule extends AnalysisRule {
  RequirePublicDocsRule()
    : super(
        name: 'minglit_require_public_docs',
        description: 'Public members must be documented.',
      );

  static const LintCode code = LintCode(
    'minglit_require_public_docs',
    'Public members must be documented.',
    correctionMessage: 'Add a documentation comment (///).',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry
      ..addClassDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor)
      ..addFunctionDeclaration(this, visitor)
      ..addEnumDeclaration(this, visitor)
      ..addMixinDeclaration(this, visitor)
      ..addExtensionTypeDeclaration(this, visitor)
      ..addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final RequirePublicDocsRule rule;

  static const _flutterLifecycleMethods = {
    'build',
    'createState',
    'initState',
    'dispose',
    'didUpdateWidget',
    'didChangeDependencies',
    'deactivate',
    'reassemble',
  };

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _checkNamedDeclaration(node, node.name.lexeme);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;
    if (_flutterLifecycleMethods.contains(name)) return;
    _checkNamedDeclaration(node, name);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkNamedDeclaration(node, node.name.lexeme);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _checkNamedDeclaration(node, node.name.lexeme);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _checkNamedDeclaration(node, node.name.lexeme);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _checkNamedDeclaration(node, node.name.lexeme);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (final variable in node.variables.variables) {
      _checkNamedDeclaration(node, variable.name.lexeme);
    }
  }

  void _checkNamedDeclaration(AnnotatedNode node, String name) {
    // Private members are excluded
    if (name.startsWith('_')) return;

    // Already documented members are excluded
    if (node.documentationComment != null) return;

    // Overridden members are excluded
    final isOverride = node.metadata.any(
      (annotation) => annotation.name.name == 'override',
    );
    if (isOverride) return;

    rule.reportAtNode(node);
  }
}
