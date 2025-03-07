[![Scrutinizer Code Quality](https://scrutinizer-ci.com/g/nystudio107/craft-twig-sandbox/badges/quality-score.png?b=v5)](https://scrutinizer-ci.com/g/nystudio107/craft-twig-sandbox/?branch=develop) [![Code Coverage](https://scrutinizer-ci.com/g/nystudio107/craft-twig-sandbox/badges/coverage.png?b=v5)](https://scrutinizer-ci.com/g/nystudio107/craft-twig-sandbox/?branch=develop) [![Build Status](https://scrutinizer-ci.com/g/nystudio107/craft-twig-sandbox/badges/build.png?b=v5)](https://scrutinizer-ci.com/g/nystudio107/craft-twig-sandbox/build-status/develop) [![Code Intelligence Status](https://scrutinizer-ci.com/g/nystudio107/craft-twig-sandbox/badges/code-intelligence.svg?b=v5)](https://scrutinizer-ci.com/code-intelligence)

# Craft Twig Sandbox

Allows you to easily create a sandboxed Twig environment where you can control what tags, filters, functions, and object methods/properties are allowed

## Requirements

Craft Twig Sandbox requires Craft CMS 5.x

## Installation

To install Craft Twig Sandbox, follow these steps:

1. Open your terminal and go to your Craft project:

        cd /path/to/project

2. Then tell Composer to require the package:

        composer require nystudio107/craft-twig-sandbox

## About Craft Twig Sandbox

Rather than just creating a new Twig `Environment` for the sandbox, Craft Twig Sandbox sub-classes the Craft `View` class, which has a few benefits:

* You get all of the Craft provided tags, filters, functions, objects, globals, etc. available to you if you want
* Plugin-provided tags, filters, functions, and objects are available if you want
* You get access to the familiar `.renderObjectTemplate()`, `.renderString()`, `.renderPageTemplate()` and `.renderTemplate()` methods
* All of the normal Craft events and scaffolding related to template rendering are present as well

It also implements an `ErrorHandler` that sub-classes the Craft `ErrorHandler` which is used to handle exceptions that happen when rendering Twig templates. This allows you to optionally display exceptions such as:

```
Twig\Sandbox\SecurityNotAllowedFunctionError
Function "dump" is not allowed in "__string_template__b0120324b463b0e0d2c2618b7c5ce3ba" at line 1.
```

## Using Craft Twig Sandbox

In its simplest form, you can create a Twig Sandbox like so:

```php
use nystudio107\crafttwigsandbox\web\SandboxView;

$sandboxView = new SandboxView();
```

This will create a new `SandboxView` that works just like the Craft web `View` class so you can use any of the `View` render methods for Twig templates:
```php
$result = $sandboxView->renderString();
$result = $sandboxView->renderObjectTemplate();
$result = $sandboxView->renderPageTemplate();
$result = $sandboxView->renderTemplate();
```

...and they will be rendered using the default `BlacklistSecurityPolicy` so blacklisted Twig tags, filters, functions, and object methods/properties will not be allowed.

If any tags, filters, functions, or object methods/properties are used that are not allowed by the security policy, a `SecurityError` exception will be thrown.

**N.B.:** For performance reasons, you should create a `SandboxView` once, and use it throughout your application's lifecycle, rather than re-creating it every time you want to render Twig using it.

### Exception handling

Note that in the above example, exceptions will be thrown if the security policy is violated; so you can handle the exception yourself if you like:

```php
use nystudio107\crafttwigsandbox\web\SandboxView;
use Twig\Sandbox\SecurityError;

$sandboxView = new SandboxView();
try {
    $result = $sandboxView->renderTemplate();
} catch (\Throwable $e) {
     // If this is a Twig Runtime exception, use the previous one instead
     if ($e instanceof SecurityError && ($previousException = $e->getPrevious()) !== null) {
         $e = $previousException;
     }
    // Exception handling here
}
```

Or if you want to use Craft's default web/console exception handling when rendering templates, you can do that like this:

```php
use nystudio107\crafttwigsandbox\web\SandboxView;

$sandboxView = new SandboxView();
try {
    $result = $sandboxView->renderTemplate();
} catch (\Throwable $e) {
    $sandboxView->sandboxErrorHandler->handleException($e)
}
```

...and the exception with a full stack trace will be displayed in the web browser, or in the console (depending on the type of the current request).

### BlacklistSecurityPolicy

The `BlacklistSecurityPolicy` is a `SecurityPolicy` that specifies the Twig tags, filters, functions, and object methods/properties that **are not** allowed.

It defaults to [reasonable subset of blacklisted](https://github.com/nystudio107/craft-twig-sandbox/blob/develop-v5/src/twig/BlacklistSecurityPolicy.php#L19) Twig tags, filters, and functions, but you can customize it as you see fit:

```php
use nystudio107\crafttwigsandbox\twig\BlacklistSecurityPolicy;
use nystudio107\crafttwigsandbox\web\SandboxView;

$securityPolicy = new BlacklistSecurityPolicy([
   'twigTags' => ['import'],
   'twigFilters' => ['base64_decode', 'base64_encode'],
   'twigFunctions' => ['dump'],
]);
$sandboxView = new SandboxView(['securityPolicy' => $securityPolicy]);
$result = $sandboxView->renderString("{{ dump() }}", []);
```

You can also control what object methods and properties are allowed to be accessed. By default, the `BlacklistSecurityPolicy` does not restrict access to any object methods or properties.

For example, if you didn't want people to be able to access the `password` property of the `DbConfig` object via:

```twig
{{ craft.app.config.db.password }}
```
or
```twig
{{ craft.app.getConfig().getDb().password }}
```
...you would do:

```php
use craft\config\DbConfig;
use nystudio107\crafttwigsandbox\twig\BlacklistSecurityPolicy;
use nystudio107\crafttwigsandbox\web\SandboxView;

$securityPolicy = new BlacklistSecurityPolicy([
   'twigProperties' => [
       DbConfig::class => ['password']
   ],
   'twigMethods' => [
       DbConfig::class => ['getPassword']
   ],
]);
$sandboxView = new SandboxView(['securityPolicy' => $securityPolicy]);
$result = $sandboxView->renderString("{{ craft.app.config.db.password }}", []);
```

If you don't want any properties or methods to be able to be accessed on a given object, you can pass in a `*` wildcard:

```php
   'twigProperties' => [
       DbConfig::class => '*'
   ],
   'twigMethods' => [
       DbConfig::class => '*'
   ],
```

### WhitelistSecurityPolicy

The `WhitelistSecurityPolicy` is a `SecurityPolicy` that specifies the Twig tags, filters, functions, and object methods/properties that **are** allowed.

It defaults to [reasonable subset of whitelisted](https://github.com/nystudio107/craft-twig-sandbox/blob/develop-v5/src/twig/WhitelistSecurityPolicy.php#L19) Twig tags, filters, functions, and object methods/properties, but you can customize it as you see fit:

```php
use nystudio107\crafttwigsandbox\twig\WhitelistSecurityPolicy;
use nystudio107\crafttwigsandbox\web\SandboxView;

$securityPolicy = new WhitelistSecurityPolicy([
   'twigTags' => ['for', 'if'],
   'twigFilters' => ['replace', 'sort'],
   'twigFunctions' => ['date', 'random'],
]);
$sandboxView = new SandboxView(['securityPolicy' => $securityPolicy]);
$result = $sandboxView->renderString("{{ dump() }}", []);
```

You can also control what object methods and properties are allowed to be accessed. By default, the `WhitelistSecurityPolicy` restricts access to all object methods or properties.

That means you must explicitly specify each object property or method.

For example, if you wanted to grant access to:

```twig
{{ craft.app.config.general.devMode }}
```
or
```twig
{{ craft.app.getConfig().getGeneral().getDevMode() }}
```
...you would do:

```php
use craft\config\GeneralConfig;
use craft\services\Config;
use craft\web\Application;
use craft\web\twig\variables\CraftVariable;
use nystudio107\crafttwigsandbox\twig\WhitelistSecurityPolicy;
use nystudio107\crafttwigsandbox\web\SandboxView;

$securityPolicy = new WhitelistSecurityPolicy([
   'twigProperties' => [
       CraftVariable::class => ['app'],
       Application::class => ['config'],
       Config::class => ['general'],
       GeneralConfig::class => ['devMode'],
   ]
   'twigMethods' => [
       Application::class => ['getConfig'],
       Config::class => ['getGeneral'],
   ],
]);
$sandboxView = new SandboxView(['securityPolicy' => $securityPolicy]);
$result = $sandboxView->renderString("{{ craft.app.config.general.devMode }}", []);
```

If you want all properties or methods to be able to be accessed on a given object, you can pass in a `*` wildcard:

```php
   'twigProperties' => [
       DbConfig::class => '*'
   ],
   'twigMethods' => [
       DbConfig::class => '*'
   ],
```

### Custom SecurityPolicy

You can also create your own custom `SecurityPolicy` to use, it just needs to conform to the Twig [`SecurityPolicyInterface`](https://github.com/twigphp/Twig/blob/3.x/src/Sandbox/SecurityPolicyInterface.php):

```php
use my\custom\SecurityPolicy;
use nystudio107\crafttwigsandbox\web\SandboxView;

$securityPolicy = new SecurityPolicy([
]);
$sandboxView = new SandboxView(['securityPolicy' => $securityPolicy]);
$result = $sandboxView->renderString("{{ dump() }}", []);
```

### Adding a SandboxView via `config/app.php`

If you want to make a Twig sandbox available globally in your Craft application, you can add the following to your `config/app.php`:

```php
use craft\config\DbConfig;
use nystudio107\crafttwigsandbox\twig\BlacklistSecurityPolicy;
use nystudio107\crafttwigsandbox\web\SandboxView;

return [
    // ...
    'components' => [
        'sandboxView' => [
            'class' => SandboxView::class,
            'securityPolicy' => new BlacklistSecurityPolicy([
                'twigProperties' => [
                    DbConfig::class => '*'
                ],
                'twigMethods' => [
                    DbConfig::class => '*'
                ],
            ]),
        ],
    ],
];
```

This will create a globally available component that you can use via:
```php
Craft::$app->sandboxView->renderString('{% set password = craft.app.getConfig().getDb().password("") %}');
```

You can even globally replace the default Craft `view` with a `SandboxView` if you want:

```php
return [
    // ...
    'components' => [
        'view' => [
            'class' => SandboxView::class,
            'securityPolicy' => new BlacklistSecurityPolicy([
                'twigProperties' => [
                    DbConfig::class => '*'
                ],
                'twigMethods' => [
                    DbConfig::class => '*'
                ],
            ]),
        ],
    ],
];
```

## Craft Twig Sandbox Roadmap

Brought to you by [nystudio107](https://nystudio107.com/)
