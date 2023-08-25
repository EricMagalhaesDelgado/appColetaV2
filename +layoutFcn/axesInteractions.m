function axesInteractions(Axes, Interactions)

    axtoolbar(Axes, Interactions);
    set(Axes.Toolbar.Children, Visible = 1)
end