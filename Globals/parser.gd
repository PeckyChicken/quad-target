class_name Parser
extends RefCounted

var token_cache: Dictionary[String,TokenizedExpression] = {}
var expression_cache: Dictionary[TokenizedExpression,ParsedExpression] = {}

enum TokenType {
	NONE = 0,
	LITERAL = 1,
	OPERATOR = 2,
	GROUPER = 3,
}

const ADD = &"+"
const SUB = &"-"
const MUL = &"*"
const DIV = &"/"

const OPERATOR_CONVERSIONS = {"+":ADD,"-":SUB,"*":MUL,"/":DIV,"×":MUL,"÷":DIV}

const OPERATOR_PRECEDENCE = {ADD:0,SUB:0,MUL:1,DIV:1}

class TokenizedExpression:
	var stack: Array = []
	func as_string(sep=" ") -> String:
		var string = ""
		for item in stack:
			if item is String and item == "(":
				string += item
				continue
			if item is String and item == ")":
				string = string.substr(0,len(string)-1) + item
				continue
			string += str(item) + sep
		return string
	
	func add(item):
		stack.append(item)
	func pop(index=-1):
		stack.pop_at(index)

class ParsedExpression:
	func add(a,b): return a+b
	func sub(a,b): return a-b
	func mul(a,b): return a*b
	func div(a,b): return a/b
	var OPERATOR_FUNCS = {ADD:add,SUB:sub,MUL:mul,DIV:div}
	
	var output_queue := []
	var operator_stack := []
	func evaluate() -> float:
		var stack: Array = []
		for item in output_queue:
			if item is int:
				stack.append(item)
			if item is StringName:
				var num2 = float(stack.pop_back())
				var num1 = float(stack.pop_back())
				var result: float = OPERATOR_FUNCS[item].call(num1,num2)
				if abs(result) == INF:
					return INF
				#print(num1," ",item," ",num2," = ",result)
				stack.append(result)
		
		return stack[0]

func is_tokenizable(string:String) -> bool:
	var tokens := TokenizedExpression.new()
	var current_token: String = ""
	var current_token_type: TokenType = TokenType.NONE
	
	var last_none_grouping_token_type: TokenType = TokenType.OPERATOR
	var last_token_type: TokenType = TokenType.OPERATOR
	var index = -1
	var left_grouper_count: int = 0
	var right_grouper_count: int = 0
	while index < len(string)-1:
		index += 1
		var last_iteration: bool = index == len(string)-1
		var character = string[index]
		if character == " ":
			if current_token_type == TokenType.LITERAL:
				tokens.add(int(current_token))
				current_token = ""
				current_token_type = TokenType.NONE
			continue
		#print(character)
		var new_token = false
		if current_token_type == TokenType.NONE:
			new_token = true
			if character.is_valid_int():
				#print("Identified a literal")
				current_token_type = TokenType.LITERAL
			elif (character in ["+","-"]) and (last_token_type in [TokenType.OPERATOR,TokenType.GROUPER]):
				if last_iteration or not string[index+1].is_valid_int():
					return false
				#print("Identified a literal from a unary")
				current_token_type = TokenType.LITERAL
			elif character in OPERATOR_CONVERSIONS:
				#print("Identified an operator")
				if last_iteration:
					return false
				if last_token_type == TokenType.OPERATOR:
					return false
				current_token_type = TokenType.OPERATOR
			elif character in "()":
				
				#print("Identified a grouper")
				current_token_type = TokenType.GROUPER
			else:
				return false
			#print(last_none_grouping_token_type)
			if last_none_grouping_token_type == TokenType.LITERAL and current_token_type == TokenType.LITERAL:
				return false
		
		last_token_type = current_token_type
		if current_token_type != TokenType.GROUPER:
			last_none_grouping_token_type = current_token_type
		match current_token_type:
			TokenType.LITERAL:
				if character.is_valid_int() or new_token:
					#print("Appended character to current literal")
					current_token += character
					
					if last_iteration:
						tokens.add(int(current_token))
					continue
				#print("Added literal to tokens")
				tokens.add(int(current_token))
				index -= 1
				current_token = ""
				current_token_type = TokenType.NONE
				continue
			TokenType.OPERATOR:
				#print("Added operator to tokens")
				tokens.add(OPERATOR_CONVERSIONS[character])
				current_token = ""
				current_token_type = TokenType.NONE
				continue
			TokenType.GROUPER:
				#print("Added grouper to tokens")
				if character == "(":
					left_grouper_count += 1
				elif character == ")":
					right_grouper_count += 1
				tokens.add(character)
				current_token = ""
				current_token_type = TokenType.NONE
				continue
			TokenType.NONE:
				return false
	if left_grouper_count != right_grouper_count:
		return false
	token_cache[string] = tokens
	return true

func tokenize(string:String) -> TokenizedExpression:
	if string not in token_cache:
		var tokenizable = is_tokenizable(string)
		assert(tokenizable,"Parser.tokenize() was called on an untokenizable string. Make sure to call Parser.is_tokenizable() before running Parser.tokenize()")
	
	return token_cache[string]

func is_parsable(expr:TokenizedExpression):
	#print("PARSING")
	var expression := ParsedExpression.new()
	var last_operator_index: int = -1
	var last_operator_layer = 0
	var current_layer = 0
	for token in expr.stack:
		if (token is int or token is float):
			expression.output_queue.append(token)
		elif token in [ADD,SUB,MUL,DIV]:
			if last_operator_layer == current_layer and expression.operator_stack and \
				OPERATOR_PRECEDENCE[expression.operator_stack[last_operator_index]] >= OPERATOR_PRECEDENCE[token]:
					expression.output_queue.append(expression.operator_stack.pop_at(last_operator_index))
			expression.operator_stack.append(token)
			last_operator_layer = current_layer
			last_operator_index = len(expression.operator_stack)-1
		elif token is String and token == "(":
			current_layer += 1
			expression.operator_stack.append(token)
		elif token is String and token == ")":
			while true:
				var operator = expression.operator_stack.pop_back()
				if not operator:
					return false
				if operator == "(":
					break
				expression.output_queue.append(operator)
			current_layer -= 1
	expression.operator_stack.reverse()
	for op in expression.operator_stack:
		expression.output_queue.append(op)
	expression.operator_stack.clear()
	expression_cache[expr] = expression
	return true

func parse_tokenized_expression(expr:TokenizedExpression) -> ParsedExpression:
	if expr not in expression_cache:
		var parsable = is_parsable(expr)
		assert(parsable,"Parser.parse_tokenized_expression() was called on an unparsable expression. Make sure to call Parser.is_parsable() before running Parser.parse_tokenized_expression()")
	
	return expression_cache[expr]
