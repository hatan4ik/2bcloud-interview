import './App.css';
import NamingContext from './NamingContext';
import { useState } from 'react';
import { createMuiTheme, Snackbar, MuiThemeProvider, Grid } from '@material-ui/core';
import MuiAlert from '@material-ui/lab/Alert';
import NamesTable from './NamesTable';
import { locationCodeMap } from './NamingService';

const Alert = (props) => {
  return <MuiAlert elevation={6} variant="filled" {...props} />;
}

const theme = createMuiTheme({
  palette: {
    type: 'dark',
  },
});


function App() {
  const [selectedResourceTypes, setSelectedResourceTypes] = useState([])
  const [workloadName, setWorkloadName] = useState("test")
  const [locationCode, setLocationCode] = useState(locationCodeMap[Object.keys(locationCodeMap)[0]])
  const [sequenceNumber, setSequenceNumber] = useState(1)
  const [environment, setEnvironment] = useState("Production")
  const [suffix, setSuffix] = useState("")
  const [subResourceSequenceNumber, setSubResourceSequenceNumber] = useState(1)


  const [copied, setCopied] = useState(false)
  const handleSnackbarClose = () => {
    setCopied(false)
  }

  return (
    <MuiThemeProvider theme={theme}>
      <Grid container alignItems="flex-start">
        <Grid item xs={12}>
          <NamingContext onSelectedResourceTypesChange={(_, val) => setSelectedResourceTypes(val)}
            onWorkloadNameChange={e => { if (e.target.value.length <= 9) setWorkloadName(e.target.value) }}
            onLocationCodeChange={e => setLocationCode(e.target.value)}
            onSequenceNumberChange={e => { if (e.target.value > 0) setSequenceNumber(e.target.value) }}
            onEnvironmentChange={e => setEnvironment(e.target.value)}
            sequenceNumber={sequenceNumber}
            locationCode={locationCode}
            environment={environment}
            selectedResourceTypes={selectedResourceTypes}
            workloadName={workloadName}
            suffix={suffix}
            onSuffixChange={e => setSuffix(e.target.value)}
            subResourceSequenceNumber={subResourceSequenceNumber}
            onSubResourceSequenceNumberChange={e => { if (e.target.value > 0) setSubResourceSequenceNumber(e.target.value) }} />
        </Grid>
        <Grid item xs={12}>
          <NamesTable selectedResourceTypes={selectedResourceTypes}
            locationCode={locationCode}
            environment={environment}
            sequenceNumber={sequenceNumber}
            workloadName={workloadName}
            setCopied={setCopied}
            suffix={suffix}
            subResourceSequenceNumber={subResourceSequenceNumber}
          />
          <Snackbar open={copied} autoHideDuration={1000} onClose={handleSnackbarClose} anchorOrigin={{ vertical:"top", horizontal:"center"}}>
            <Alert onClose={handleSnackbarClose} severity="success" sx={{ width: '100%' }}>
              Copied to clipboard!
            </Alert>
          </Snackbar>
        </Grid>
      </Grid>
    </MuiThemeProvider>
  );
}

export default App;
