return function(Window)
    local MainTab = Window:CreateTab("Main", nil)
    MainTab:CreateSection("Main Features")
    MainTab:CreateButton({
        Name = "Test Button",
        Callback = function()
            print("Test button clicked!")
        end
    })
end
