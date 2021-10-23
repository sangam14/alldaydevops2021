package accurics

# Full Rego Documentation: https://www.openpolicyagent.org/docs/latest/
# 'input' keyword is used to read the config
# To access nested variables use the dot notation
# e.g. : input.variable.name
# To access any value from an array use [index] after the array name
# e.g. : input.array[1]
# The [_] index allows is used to handle arrays in a single line.
# If used in an assignment expression (x := y[_]), x's value will be the array (y[_])
# If used in a comparison expression (y[_].name = x), the entire condition will be true if there exists at least one document in y for which the comparison is true.

#IAC_TYPE:terraform
#IAC_PATH:terraform-rego/main.tf

# This is an example for a Rego rule. The value inside the brackets [array.id] is returned if the rule evaluates to be true.
# This rule will return the 'id' of every document in 'array' that has 'authorization' key set to "NONE"

{{.prefix}}{{.name}}{{.suffix}}[array.id] {
	 array := input.aws_s3_bucket[_]
	 array.config.acl == "public-read"
	# array.config.bucket == ""
	# array.config.cors_rule == []
	# array.config.policy == ""

}
