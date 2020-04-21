<br/>
# Energy Predictor

### - [Notebook Walkthrough](https://sammyzysheng.github.io/ML2-TP2-Team3/Energy-Predictor)
<br/>
<br/>

Over the semester, each team will pick a business-related Kaggle competition, or the Quantopian competition, to research and critique. On the last day of class, the team will give a 15-minute presentation on their Kaggle research project. The presentation should cover 
1. An overview of the Kaggle/Quantopian competition - what's the objective? where does the dataset come from? what are the key features?
Background: 
The ASHRAE Great Energy Predictor III competition revolves around predicting how much energy a building will consume based on variables such as meter type, primary use of building, square footage, year built, and weather. With better estimates of energy-saving investments, investors and institutions will be more inclined to invest in eco-friendly features and upgrades.
The sponsor of the Kaggle competition is the American Society of Heating, Refrigerating and Air-Conditioning Engineers (ASHRAE), an American professional association pursuing the advancement of heating, ventilation, air conditioning and refrigeration. A core component to ASHRAE’s purpose pertains to the development and publishing of technical standards to improve building services engineering, energy efficiency, indoor air quality, and sustainable development.
Dataset:
ASHRAE’s Great Energy Predictor included five separate data sources. Fortunately for us, two of these datasets pertained to the test datasets in which ASHRAE would measure performance. We discarded the testing datasets altogether since they did not include meter readings, the variable we are interested in predicting.
Discarding the testing datasets left us with three data sources. The first data source contained information regarding the individual buildings metadata. Buildings metadata contains a site identifier, building identifier, the primary use of the building (education, office, retail, etc.), square footage, year built, and number of floors. The second data source included information such as the building identifier, meter type (electricity, chilled water, steam, hot water), a timestamp, and energy consumption. The final data source contained weather data from nearby meteorological stations such as site identifier, air temperature, cloud coverage, dew temperature, precipitation depth, sea level pressure, wind direction, and wind speed.
2. A brief critique of select Notebooks on this competition available in the public domain - The team should critically evaluate other people's published work using concepts learned from the Machine Learning 1 and Machine Learning 2 coursework.


