# What happens when data go missing?

Explore missing values with a small interactive dataset: hide measurements, compare estimates and reveal the original values.

A missing measurement is a gap in our knowledge. Try filling a few gaps and see how the choice of method changes the answer.

1.  **Hide measurements** by changing the amount or pattern of missing data.
2.  **Fill the gaps** with a simple method and compare its estimates with the other methods.
3.  **Reveal the original values** to see what the estimates recovered.

THE MISSING-DATA SANDBOX12 samples · 4 features · synthetic data

Choose missing data and an estimation method

Measurements to hide

25%

Which values go missing?Values chosen at randomLow values more likely

Fill gaps usingFeature meanFeature medianThree nearest samples

Fill the gaps

Try another set

Reset

Reveal the original values behind the gaps

Loading the sample dataset…

| Sample | Feature A | Feature B | Feature C | Feature D |
|--------|-----------|-----------|-----------|-----------|

Illustrative measurements in arbitrary units (a.u.). Dashed cells mark hidden or estimated values. {#demo-data}

Dashed border = a gap or estimate. Colour indicates the value; every cell also has a number or “?”.

## How close are the estimates?

Average absolute error on the hidden values, in a.u. Lower means closer to the originals.

Fill the gaps to compare the three methods on exactly the same hidden values.

How do these methods work?

**Feature mean:** use the average of that feature’s visible measurements.

**Feature median:** use their middle value.

**Three nearest samples:** compare samples using their shared, visible features, scale each feature by its visible range, and average the target values of up to three nearest donors. If there is no comparable donor, use the feature mean.

## What does this tell us?

Here we know the original values because we deliberately hid them. That lets us measure the error. In a real experiment, the missing values are unknown, so the reason they are missing and the assumptions behind an algorithm matter.

This is a learning example with synthetic data and three simple methods. Its rankings describe this example and this hidden set. They are not the published imputomics benchmark or a recommendation for analysing a real dataset.

[Read the imputomics story](../subsite/stories.llms.md#imputomics) [Explore the full imputomics application ↗](https://biogenies.info/imputomics-ws)

[Missing-value research](../subsite/topics/mvi.llms.md) · [Software catalogue](../subsite/software.llms.md)
