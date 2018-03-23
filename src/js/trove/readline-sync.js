({
    provides: {},
    requires: [],
    nativeRequires: ["readline-sync"],
    theModule: function(runtime, _, uri, readlineSync) {
        function prompt(options){
            return readlineSync.prompt(options);
        }
        return runtime.makeModuleReturn({
            "prompt": runtime.makeFunction(prompt, "prompt")
        },
        {});
    }
})
