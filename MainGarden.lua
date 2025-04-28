return function(MainTab)
    -- Add a section to the tab
    MainTab:CreateSection("Movement")

    -- Example toggle
    MainTab:CreateToggle({
        Name = "Enable Fly",
        CurrentValue = false,
        Callback = function(Value)
            if Value then
                print("Fly enabled!")
            else
                print("Fly disabled!")
            end
        end
    })

    -- Add more features here as needed
end
