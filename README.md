---
title: 严格按照要求使用（Eslint,pretter,husky,lint-staged）进行代码格式约束
author: 罗润峰
date: '2022-01-13'
---
> 本文采用了`yarn`作为包管理器，`npm`操作类似，搭建一个`Vue3`+ `Vite` + `typeScript` + `Eslint` + ``prettier`` + `Husky` + `Lint-staged` 严格进行代码格式化以及提交git前自动审核代码是否过关.

## 一. 初始化项目

``` js
// 创建一个空的 vue3-ts 项目,
yarn create vite my-vue-app --template vue-ts
// 安装依赖
cd my-vue-app && yarn
// 默认是没有创建git仓库的，这里我们初始化一下
git init
```
 `注意`： 这里git初始化可以使用另外的一个文件夹下初始化，然后拷贝git文件到项目根目录下
## 二. 集成`Eslint`
1. 首先我们安装eslint
   ``` 
   yarn add eslint  -D
   ```
2. 接下来初始化eslint:
   ```
   npx eslint --init
   ```
   依次选择这些选项: 
   ![这里写图片描述](../../../assets/schem/code/code-format/stup1.png)  
   到最后一步时会弹一个这个提示,问是否立即用npm安装这个三个依赖，这里我们选否，并且手动拷贝出来用yarn安装。(`别问为啥，问就是npm太慢`)
   ```
   yarn add eslint-plugin-vue@latest @typescript-eslint/eslint-plugin@latest @typescript-eslint/parser@latest -D
   ```

4. 到这一步，我们就已经安装了相关的依赖了，并且得到一个已配置好的.eslintrc.json文件：
   ```json 
   {
    "env": {
        "browser": true,
        "es2021": true,
        "node": true
    },
    "extends": [
        "eslint:recommended",
        "plugin:vue/essential",
        "plugin:@typescript-eslint/recommended"
    ],
    "parserOptions": {
        "ecmaVersion": 13,
        "parser": "@typescript-eslint/parser",
        "sourceType": "module"
    },
    "plugins": [
        "vue",
        "@typescript-eslint"
    ],
    "rules": {
        }
    }
   ```
5. 然后我们为package.json文件增加一个lint命令，这个命令我们后期将会用来检查我们的代码是否符合Eslint规范，当然这个再后面我们并不会手动去检查，我们将会使用到一个插件`Lint-staged`会自动给我们审核的，接着往下看
   ```json
   {
    "scripts":{
        // lint当前项目中的文件并且开启自动修复
        "lint": "eslint . --ext .vue,.js,.ts,.jsx,.tsx --fix",
     }
   }
   ```
6. 一切进行得非常顺利，然而当我们运行lint命令时，会发现不是我们想要的结果
      ![这里写图片描述](../../../assets/schem/code/code-format/setup2.png)
  **原因** ：命令行在解析vue文件会报parsing error。这是因为，默认eslint不会解析vue文件，所以我们需要一个额外的解析器来帮我们解析vue文件。   
  这一步本来是在我们继承plugin:vue/essential的时候，默认为我们配置了的
  ![这里写图片描述](../../../assets/schem/code/code-format/setup3.png)   
    但是我们后续又extend了`"plugin:@typescript-eslint/recommended"`,它又继承来自`./node_modules/@typescript-eslint/eslint-plugin/dist/configs/base.js`
  ```js
   "use strict";
    // THIS CODE WAS AUTOMATICALLY GENERATED
    // DO NOT EDIT THIS CODE BY HAND
    // YOU CAN REGENERATE IT USING yarn generate:configs
    module.exports = {
        parser: '@typescript-eslint/parser',
        parserOptions: { sourceType: 'module' },
        plugins: ['@typescript-eslint'],
    };
    //# sourceMappingURL=base.js.map
  ```
  而我们在配置文件中的extends顺序是：
  ```json
    {
        "extends": [
            "eslint:recommended",
            "plugin:vue/essential",
            "plugin:@typescript-eslint/recommended"
        ],
    }
  ```
   所以`vue-eslint-parser`被`@typescript-eslint/parser`覆盖了。这里我们只需要将外部的parser改为`vue-eslint-parser`，并且在`parserOptions`中添加一个`parser:@typescript-eslint/parser`属性即可，而这一步我们之前的配置文件里面已经有做了

   ```json
    {
        ...
        // 新增，解析vue文件
        "parser":"vue-eslint-parser",
        "parserOptions": {
            "ecmaVersion": "latest",
            "parser": "@typescript-eslint/parser",
            "sourceType": "module"
        },
        ...
    }
   ```   
   两个parser的区别在于，外面的parser用来解析vue文件，使得eslint能解析`<template>`标签中的内容，而`parserOptions`中的`parser`，即`@typescript-eslint/parser`用来解析vue文件中`<script>`标签中的代码。

   接下来我们继续运行 `yarn run lint`,会发现又报错了：   
   ![这里写图片描述](../../../assets/schem/code/code-format/setup5.png)   
   这里一共报两个问题:
   - `<template>`节点要求有且只有一个根节点
   - 找不到`defineProps`的定义
  
  我们知道，这两个特性都是vue3引入的，问题可能出在我们的配置不支持vue3项目，翻阅`./node_modules/eslint-plugin-vue`目录的相关配置，便可发现问题所在，`eslint-plugin-vue`提供了几个预设的配置集。
  ```js
  configs: {
    base: require('./configs/base'),
    essential: require('./configs/essential'),
    'no-layout-rules': require('./configs/no-layout-rules'),
    recommended: require('./configs/recommended'),
    'strongly-recommended': require('./configs/strongly-recommended'),
    'vue3-essential': require('./configs/vue3-essential'),
    'vue3-recommended': require('./configs/vue3-recommended'),
    'vue3-strongly-recommended': require('./configs/vue3-strongly-recommended')
  },
  ```
  没有vue3-前缀的规则集对应vue2项目，vue3-开头的对应vue3项目。而我们默认使用的是 `vue/essential`这个规则集，由于我们是vue3项目，所以应该使用vue3的规则集，这里使用`vue3-recommended`

```json
{
    "extends": [
        "eslint:recommended",
        -- "plugin:vue/essential",
        ++ "plugin:vue/vue3-recommended",
        "plugin:@typescript-eslint/recommended"
    ],
}
```
然后再运行,`yarn run lint`,发现还是会报错。
   ![这里写图片描述](../../../assets/schem/code/code-format/setup6.png)   
因为defineProps是一个全局的预编译宏，eslint不知其定义在哪里，所以需要在global选项中将其标注出来，然而我阅读了`eslint-plugin-vue`这个文件后，发现它已经预设了。

```js
  environments: {
    'setup-compiler-macros': {
      globals: {
        defineProps: 'readonly',
        defineEmits: 'readonly',
        defineExpose: 'readonly',
        withDefaults: 'readonly'
      }
    }
  }
```
我们只需要在env中开启这个环境变量即可：
```js
{
    "env": {
        "browser": true,
        "es2021": true,
        "node": true,
        // 开启setup语法糖环境
         ++ "vue/setup-compiler-macros":true
    },
}
```
 Ok，到此为止，然后我们再运行yarn run lint,oh 谢天谢地，终于不报错了。

## 三. 添加`vscode-eslint` 插件
就目前而言，我们能在命令行中使用eslint了，然而写一行代码就去运行下检测脚本实在太麻烦，好在我们可以结合eslint插件使用。   
在vscode中安装好eslint插件,它便会在我们写代码的时候对我们的脚本进行lint，我们就没必要再运行`yarn run lint` 了。同时，我们可以新建一个`.vscode/settings.json`文件，为这个本项目开启自动修复
```js
{
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```
这样一来，当你按下ctrl + s保存的时候，eslint便会智能地为你修复一些代码错误了。
## 四. 集成 `prettier`
相比 eslint 而言 `prettier` 就会要温和一些了。 `prettier` 并没有提供太多的配置选项给我们选择,所以我们在网上随便找一份配置就行。   
```js
yarn add prettier -D
```
然后再项目根目录添加一份配置文件   
```js
// .`prettier`rc.js
module.exports = {
  printWidth: 80, //单行长度
  tabWidth: 2, //缩进长度
  useTabs: false, //使用空格代替tab缩进
  semi: true, //句末使用分号
  singleQuote: true, //使用单引号
}
```
这是我的配置文件，如果需要更多的配置方法，可以参考 **[官方的配置文档](https://prettier.io/docs/en/options.html)**   
然后再package.json中添加一个脚本

```js
{
    "scripts":{
        "format": "prettier --write ./**/*.{vue,ts,tsx,js,jsx,css,less,scss,json,md}"
    }
}
```
当运行这个命令时，就会将我们项目中的文件都格式化一次。   

一般而言，我们还需要集成 `prettier`这个插件来完成自动保存格式化，在插件市场安装好了以后，在我们的`.vscode/settings.json`中添加如下规则
```js
{
   "editor.formatOnSave": true, // 开启自动保存
   "editor.defaultFormatter": "esbenp.prettier-vscode", // 默认格式化工具选择`prettier`
}
```
这样一来，当我们在vscode写代码的时候，便会自动格式化了。

## 五. 解决 `eslint` 和 `prettier` 的冲突
- 理想状态下，到这一步我们写代码的时候，eslint 和 `prettier`会相互协作，既美化我们的代码，也修复我们质量不过关的代码。然而现实总是不那么完美，我们会发现某些时候，`eslint`提示错误，我们修改了以后，屏幕会闪一下然后又恢复到报错状态，自动修复失效了   
- 这是因为eslint 有一部分负责美化代码的规则和 `prettier`的规则冲突了， 用 `eslint-config-prettier` 提供的规则集来覆盖掉eslint冲突的规则，并用`eslint-plugin-prettier`来使eslint使用`prettier`的规则来美化代码。

```js
yarn add eslint-config-prettier eslint-plugin-prettier -D
```
- 然后在 .eslintrc.json中extends的最后添加一个配置:
```js 
  "extends": [
    "eslint:recommended",
    "plugin:vue/vue3-recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:prettier/recommended" // 新增，必须放在最后面
  ],
```
然后我们重启一下vscode，就会发现冲突消失了，我们的自动修复和自动格式化也能相互协作了

## 六. 配置 `husky `+ `lint-staged`
理论上，到上一步我们已经能使得我们的项目获得不错的开发规范约束了。然而仍然有可以改进的地方：
- 如果是在项目中途才接入`eslint + prettier``,如果对原来的代码使用`yarn run lint` 或者 `yarn run format`势必会带来大范围地改动，甚至会造成冲突。
- 对于一些不使用`vscode`编辑器，或者没有安装`prettier`和`eslint`插件的用户而言，他们不能享受到插件带来的协助，而他们的代码自然大概率是不符合规范的，不该被提交到代码库。  
  
基于上述的顾虑，社区提供了 `husky` + `lint-staged`的渐进式方案。 `lint-staged` 是一个只检测`git`暂存区的`lint`工具，`husky`是一个用来给我们的项目添加`git hook`的工具，`git hook`是进行`git`操作会触发的脚本，例如：提交的时候会触发`pre-commit`钩子,输入提交信息会触发`commit-msg`钩子。 我们用`husky`安装`pre-commit`钩子，我们就可以在进行`git commit`操作的时候，运行我们的脚本来检测待提交的代码是否规范，便可以只对暂存区的文件进行检查

```json 
yarn add husky lint-staged -D
```
- 添加一个在`package.json`中添加一条`preinstall`脚本

```js
{
    "script":{
        "prepare": "husky install"
    }
} 
```
- prepare脚本会在 `yarn install` 之后自动运行，这样依赖你的小伙伴`clone`了你的项目之后会自动安装`husky`,这里由于我们已经运行过 `yarn install` 了，所以我们需要手动运行一次`yarn run prepare`,然后我们就会得到一个目录`.husky`。
- 接下来我们为我们git仓库添加一个`pre-commit`钩子,运行   
```js
{
   npx husky add .husky/pre-commit "npx --no-install lint-staged"
} 
```
- 这回在我们的`.husky`目录下生成一个pre-commit的脚本
 ```js 
 #!/bin/sh 
. "$(dirname "$0")/_/husky.sh"

npx --no-install lint-staged
 ```
 - 接下来我们配置`lint-staged`,在`package.json`中添加下面的配置信息。
```js 
{
  "lint-staged": {
    "*.{js,vue,ts,jsx,tsx}": [
      "prettier --write",
      "eslint --fix"
    ],
    "*.{html,css,less,scss,md}": [
      "prettier --write"
    ]
  }
}
 ```
 这样之后，我们后续提交到暂存区的代码也就会被`eslint+`prettier``格式化和检查，进一步保证我们的代码规范
## 七. 配置文件总览
```js
// package.json
{
  "name": "my-vue-app",
  "version": "0.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc --noEmit && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext .vue,.js,.ts,.jsx,.tsx --fix",
    "format": "prettier --write ./**/*.{vue,ts,tsx,js,jsx,css,less,scss,json,md}",
    "prepare": "husky install"
  },
  "dependencies": {
    "vue": "^3.2.25"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^5.7.0",
    "@typescript-eslint/parser": "^5.7.0",
    "@vitejs/plugin-vue": "^2.0.0",
    "eslint": "^8.4.1",
    "eslint-config-prettier": "^8.3.0",
    "eslint-plugin-prettier": "^4.0.0",
    "eslint-plugin-vue": "^8.2.0",
    "husky": "^7.0.4",
    "lint-staged": "^12.1.3",
    "prettier": "^2.5.1",
    "typescript": "^4.4.4",
    "vite": "^2.7.2",
    "vue-tsc": "^0.29.8"
  },
  "lint-staged": {
    "*.{js,vue,ts,jsx,tsx}": [
      "prettier --write",
      "eslint --fix"
    ],
    "*.{html,css,less,scss,md}": [
      "prettier --write"
    ]
  }
}

// .eslintrc.json
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true,
    "vue/setup-compiler-macros": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:vue/vue3-recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:prettier/recommended"
  ],
  "parser": "vue-eslint-parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "parser": "@typescript-eslint/parser",
    "sourceType": "module"
  },
  "plugins": ["vue", "@typescript-eslint"],
  "rules": {}
}

// .prettierrc.js
module.exports = {
  printWidth: 80, //单行长度
  tabWidth: 2, //缩进长度
  useTabs: false, //使用空格代替tab缩进
  semi: true, //句末使用分号
  singleQuote: true, //使用单引号
};

// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}

// .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx --no-install lint-staged
 ```
## 八. 总结
本文从实战出发,抱着一个边学习边分享的态度，为一个 vite-vue3-ts 项目添加了eslint + prettier + husky + lint-staged项目规范，希望大家能从中学到知识。代码已经上传到 **[github](https://github.com/aBigFace/program-schema-code-vue3)** 上,点击这里即可查看。

