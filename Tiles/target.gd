class_name Target
extends PanelContainer

var number_range := Vector2i(10,60)

var solution: String

var OPS = ["+","-","*","/"]

@onready var root: Root = $".."
@onready var target_range := Vector2i(4,20) * root.number_count


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
		
	if root.difficulty == Root.Difficulty.easy:
		OPS = ["+","-"]
	
	
	if not root.save_data["success"]:
		root.target = -1
		
		root.puzzle_seed *= (root.difficulty as int + 1)
		@warning_ignore("narrowing_conversion")

		assert (root.puzzle_seed is int,"Puzzle seed must be an integer, float found.")
		
		while root.target == -1:
			root.starting_numbers = create_numbers(root.puzzle_seed)
			root.target = create_target(root.starting_numbers,root.puzzle_seed,10**int(root.difficulty==Root.Difficulty.harder))
			root.puzzle_seed += 1
		
		root.puzzle_seed -= 1
	
	root.create_number_tiles(root.starting_numbers)
	root.create_target_tile()

func create_numbers(puzzle_seed:int=-1) -> Array[int]:
	if puzzle_seed != -1:
		seed(puzzle_seed)
	var numbers: Array[int] = []
	var harder_mode := root.difficulty==Root.Difficulty.harder
	for __ in range(root.number_count):
		var n = randi_range(number_range.x*(10**int(harder_mode)),number_range.y*(10**int(harder_mode)))
		while n in numbers:
			n = randi_range(number_range.x*(10**int(harder_mode)),number_range.y*(10**int(harder_mode)))
		numbers.append(n)
	
	numbers.sort()
	return numbers

func _get_permutations(arr: Array) -> Array:
	var result: Array = []
	if arr.size() == 0:
		return [[]]
	for i in range(arr.size()):
		var elem = arr[i]
		var rest = arr.duplicate()
		rest.remove_at(i)
		for p in _get_permutations(rest):
			result.append([elem] + p)
	return result


func get_all_subarrays(arr: Array) -> Array[Array]:
	var all: Array[Array] = [[]]  # include empty array
	var n = arr.size()
	
	# generate all subsets
	for mask in range(1, 1 << n):
		var subset: Array = []
		for j in range(n):
			if mask & (1 << j):
				subset.append(arr[j])
		# for each subset, add all permutations
		for p in _get_permutations(subset):
			all.append(p)
	
	return all

func get_all_choices(arr: Array, k: int) -> Array[Array]:
	var choices: Array[Array] = []
	var n: int = arr.size()
	var total: int = int(pow(n, k))  # total number of choices
	
	for index in range(total):
		var choice: Array = []
		var num = index
		for _i in range(k):
			var digit = num % n
			choice.insert(0, arr[digit])  # build from rightmost position
			@warning_ignore("integer_division")
			num = num / n
		choices.append(choice)
	
	return choices

func is_possible(numbers:Array[int],ops:Array[String],target:int) -> bool:
	
	var combinations = get_all_subarrays(numbers)
	for combination in combinations:
		if len(combination) <= 2: #Already checked for
			continue
		var operation_combinations = get_all_choices(ops,len(combination)-1)
		
		for op_comb in operation_combinations:
			var expression = ""
			for index in range(len(op_comb)):
				expression += str(combination[index]) + op_comb[index]
			expression += str(combination.back())
			var parser: Expression = Expression.new()
			parser.parse(expression)
			if parser.execute() == target:
				return true
	
	return false

func evaluate_op(num1:float,num2:float,op:String) -> float:
	assert(op in OPS,"Operator %s is not recognised. Valid operators are %s" % [op,", ".join(OPS)])
	if op == "+":
		return num1 + num2
	elif op == "-":
		return num1 - num2
	elif op == "*":
		return num1 * num2
	elif op == "/":
		return num1 / num2
	
	assert(false,"How did operator %s miss the previous assertion?" % [op])
	return -INF

func check_one_operation(numbers,target):
	for num1 in numbers:
		for num2 in numbers:
			for op in OPS:
				if evaluate_op(num1,num2,op) == target:
					return true
	return false

func create_target(numbers: Array[int],puzzle_seed:int,multiplier=1) -> int:
	var local_target_range = target_range*multiplier
	numbers = numbers.duplicate()
	var target: int = -1
	var attempts: int = 0
	var start = true
	
	seed(puzzle_seed)
	while start or target in numbers or local_target_range.x > target or local_target_range.y < target or check_one_operation(numbers,target) or (root.difficulty != Root.Difficulty.easy and is_possible(numbers,["+","-"],target)):
		if attempts >= 50:
			return -1
		attempts += 1
		start = false
		solution = ""
		target = -1
		numbers.shuffle()
		
		var used_operations: Array[String] = []
		
		var index = -1
		while index < len(numbers)-1:
			index += 1
			var number = numbers[index]
			
			if target == -1:
				target = number
				solution = str(number)
				continue
			
			var operation: String
			
			if root.difficulty != Root.Difficulty.easy and index == len(numbers)-1 and "*" not in used_operations:
				operation = "*"
			else:
				operation = OPS.pick_random()
			
			used_operations.append(operation)
			var evaluation = evaluate_op(target,number,operation)
			
			if evaluation != round(evaluation) or abs(evaluation) == INF:
				used_operations.pop_back()
				index -= 1
				continue
			
			target = int(evaluation)
			solution += operation + str(number)
	
	return target

func _process(_delta: float) -> void:
	pass
