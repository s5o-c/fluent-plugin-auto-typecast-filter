# Fluent::Plugin::AutoTypecastFilter [![Gem Version](https://badge.fury.io/rb/fluent-plugin-auto-typecast-filter.svg)](https://badge.fury.io/rb/fluent-plugin-auto-typecast-filter)

This plug-in helps to automatically cast and retransmit structured log data flowing through the Fluent network.

## Tested dependencies

* fluentd v1.7.0

## Installation

```sh
gem install fluent-plugin-auto-typecast-filter
```

or

```sh
# for `fluent-gem` users:
fluent-gem install fluent-plugin-auto-typecast-filter
```

## Usage

Basic usage in fluentd.conf:

```
<filter any.tag.**>
    @type auto_typecast
</filter>
```

## Parameters

| Parameter | Description | Default |
---|---|---
| maxdepth | Specifies the maximum level of nesting that is autocast. If **`0`** is specified, all nests are targeted. | 1 |

## Examples

**Case 1:**

```plain
# CONFIG:
maxdepth 0

# INPUT:
{ 'k': { 'k': { 'k': [ { 'k': {
    'k0': 'string',
    'k1': '20',
    'k2': '1.0',
    'k3': 'NULL',
    'k4': 'true'
} } ] } } }

# FILTERED OUTPUT:
{ 'k': { 'k': { 'k': [ { 'k': {
    'k0': 'string',
    'k1': 20,
    'k2': 1.0,
    'k3': null,
    'k4': true
} } ] } } }
```

**Case 2:**

```plain
# CONFIG:
maxdepth 3

# INPUT:
{ 'k' : {
    'k0': [ '10', '20', '30' ],
    'k1': {
        'k': [ '10', '20', '30' ]
    }
}

# FILTERED OUTPUT:
{ 'k' : {
    'k0': [ 10, 20, 30 ]
    'k1': {
        'k': [ '10', '20', '30' ]
    }
}
```

## Copyright

* Copyright (c) 2019- Shotaro Chiba
* Apache License, Version 2.0
