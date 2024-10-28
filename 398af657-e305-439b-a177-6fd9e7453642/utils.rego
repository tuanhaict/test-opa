package permit.generated.abac.utils

import future.keywords.in

# not undefined if object 'x' has a key 'k'
has_key(x, k) {
	_ := x[k]
}

# If a field 'k' relies in both 'a' and 'b' objects, pick its value from 'a'.
pick_first(k, a, b) = a[k] {
	has_key(a, k)
}

else = b[k] {
	true
}

# Merging objects a & b. If a field relies in both of them, pick it's value from a.
# It is deprecated in favor of object.union, but we keep it for backward compatibility.
merge_objects(a, b) = c {
	c := object.union(a, b)
}

object_keys(obj) := result {
	result := [key | some key, value in obj]
}

user_roles[roleKey] {
	some roleKey in data.users[input.user.key].roleAssignments[input.resource.tenant]
}

user_tenants[tenant] {
	some tenant in object_keys(data.users[input.user.key].roleAssignments)
}

__generated_user_attributes = {
	"roles": user_roles,
	"tenants": user_tenants,
}

__generated_resource_attributes = {"type": input.resource.type}

default __user_in_tenant = false

__user_in_tenant {
	input.resource.tenant in user_tenants
}

default __stored_user_attributes = {}

__stored_user_attributes = data.users[input.user.key].attributes

default __stored_resource_attributes = {}

__stored_resource_attributes = data.resource_instances[sprintf("%s:%s", [input.resource.type, input.resource.key])].attributes

# Stored tenant attributes only work if the input user is a member
default __stored_tenant_attributes = {}

__stored_tenant_attributes = result {
	__user_in_tenant
	result := data.tenants[input.resource.tenant].attributes
}

# Stored role attributes
__stored_role_attributes := {role_key: role_attrs |
	role_key := user_roles[_]
	role_attrs := data.roles[role_key].attributes
}

default __input_user_attributes = {}

default __input_resource_attributes = {}

default __input_tenant_attributes = {}

default __input_context_attributes = {}

default __custom_user_attributes = {}

default __custom_resource_attributes = {}

default __custom_tenant_attributes = {}

default __custom_role_attributes = {}

default __custom_context_attributes = {}

__input_user_attributes = input.user.attributes

__input_resource_attributes = input.resource.attributes

__input_tenant_attributes = input.tenant.attributes

__input_context_attributes = input.context

__custom_user_attributes = data.permit.custom.custom_user_attributes

__custom_tenant_attributes = data.permit.custom.custom_tenant_attributes

__custom_role_attributes = data.permit.custom.custom_role_attributes

__custom_resource_attributes = data.permit.custom.custom_resource_attributes

__custom_context_attributes = data.permit.custom.custom_context_attributes

# For each attribute, the order of preference is:
#   input - What was given in the request, if any
#   custom - Attributes generated by custom Rego code
#   stored - Attributes from Permit's database and backend
#   generated - Atrributes generated in this file

__user_attributes = object.union_n([
	__generated_user_attributes, __stored_user_attributes,
	__custom_user_attributes,
	__input_user_attributes,
])

__resource_attributes = object.union_n([
	__generated_resource_attributes, __stored_resource_attributes,
	__custom_resource_attributes,
	__input_resource_attributes,
])

__tenant_attributes = object.union_n([
	__stored_tenant_attributes, __custom_tenant_attributes,
	__input_tenant_attributes,
])

__role_attributes = object.union_n([
	__stored_role_attributes,
	__custom_role_attributes,
])

__context_attributes = object.union(
	__custom_context_attributes,
	__input_context_attributes,
)

attributes = {
	"user": __user_attributes,
	"resource": __resource_attributes,
	"tenant": __tenant_attributes,
	"context": __context_attributes,
	"roles": __role_attributes,
	# TODO: When we want to add data from system, use these
	#	"resource": object.union(__input_resource_attributes, data.resource[input.resource.id].attributes),
	#	"environment": object.union(__input_context_environment, data.environment.attributes),

}

condition_set_permissions := data.condition_set_rules