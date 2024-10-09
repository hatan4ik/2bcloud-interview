import React, { useEffect, useState } from 'react'
import { Paper, FormControl, Grid, Input, InputLabel, FormHelperText, Select, MenuItem, TextField } from '@material-ui/core'
import Autocomplete from '@material-ui/lab/Autocomplete';
import { environments, supportedConventions, locationCodeMap } from './NamingService';

const NamingContext = (props) => {
    const [resourceTypesDb, setResourceTypesDb] = useState([])

    const getResourceTypesDb = () => {
        fetch('resources.json')
            .then(function (response) {
                return response.json()
            }).then(function (resources) {
                setResourceTypesDb(resources.filter(r => supportedConventions.indexOf(r.convention) >= 0))
            })
    }

    useEffect(() => {
        getResourceTypesDb()
    }, [])

    return (
        <div style={{ padding: 16 }}>
            <Paper style={{ padding: 15 }} aria-level={3}>
                <Grid container alignItems="flex-start" spacing={2}>
                    <Grid item lg={4} md={6} sm={6} xs={12}>
                        <FormControl>
                            <Autocomplete
                                multiple
                                disableCloseOnSelect
                                size="small"
                                limitTags={2}
                                ListboxProps={{ style: { maxHeight: "15rem" }, position: "bottom-start" }}
                                value={props.selectedResourceTypes}
                                options={resourceTypesDb}
                                onChange={props.onSelectedResourceTypesChange}
                                getOptionLabel={(option) => option.name ? option.name.replaceAll('_', ' ') : ""}
                                renderInput={(params) => <TextField {...params} label="Resource Type" variant="outlined" />}
                            />
                            <FormHelperText id="resource-type-helper-text">The Azure Resource Type (storage accout, key vault ...).</FormHelperText>
                        </FormControl>
                    </Grid>
                    <Grid item lg={4} md={6} sm={6} xs={12}>
                        <FormControl >
                            <InputLabel htmlFor="workload-name">Workload Name</InputLabel>
                            <Input id="workload-name" aria-describedby="workload-name-helper-text" onChange={props.onWorkloadNameChange} value={props.workloadName} />
                            <FormHelperText id="workload-name-helper-text">The workload name.</FormHelperText>
                        </FormControl>
                    </Grid>
                    <Grid item lg={4} md={6} sm={6} xs={12}>
                        <FormControl >
                            <InputLabel htmlFor="location">Location</InputLabel>
                            <Select id="location" aria-describedby="location-helper-text" onChange={props.onLocationCodeChange} value={props.locationCode}>
                                {
                                    Object.entries(locationCodeMap).map(([key, value]) => <MenuItem key={value} value={value}>{key}</MenuItem>)
                                }
                            </Select>
                            <FormHelperText id="location-helper-text">The location of the resource.</FormHelperText>
                        </FormControl>
                    </Grid>
                    <Grid item lg={4} md={6} sm={6} xs={12}>
                        <FormControl >
                            <InputLabel htmlFor="environment">Environment</InputLabel>
                            <Select id="environment" aria-describedby="environment-helper-text" onChange={props.onEnvironmentChange} value={props.environment}>
                                {
                                    environments.map(env => <MenuItem key={env.toLowerCase()} value={env}>{env}</MenuItem>)
                                }
                            </Select>
                            <FormHelperText id="environment-helper-text">The target environment.</FormHelperText>
                        </FormControl>
                    </Grid>
                    <Grid item lg={4} md={6} sm={6} xs={12}>
                        <FormControl >
                            <InputLabel htmlFor="sequence-number">Sequence Number</InputLabel>
                            <Input type="number" id="sequence-number" aria-describedby="sequence-number-helper-text" value={props.sequenceNumber} onChange={props.onSequenceNumberChange} />
                            <FormHelperText id="sequence-number-helper-text">The sequence number of the resource.</FormHelperText>
                        </FormControl>
                    </Grid>
                    {
                        props.selectedResourceTypes.filter((item) => item.convention.includes('suffix')).length > 0 ? (
                            <Grid item lg={4} md={6} sm={12} xs={12}>
                                <FormControl >
                                    <InputLabel htmlFor="suffix">Suffix</InputLabel>
                                    <Input id="suffix" aria-describedby="suffix-helper-text" value={props.suffix} onChange={props.onSuffixChange} />
                                    <FormHelperText id="suffix-helper-text">The suffix.</FormHelperText>
                                </FormControl>
                            </Grid>
                        ) : null
                    }
                    {
                        props.selectedResourceTypes.filter((item) => item.convention === "vm_subresource").length > 0 ? (
                            <Grid item lg={4} md={6} sm={12} xs={12}>
                                <FormControl >
                                    <InputLabel htmlFor="sub-resource-sequence-number">Sub Resource Sequence Number</InputLabel>
                                    <Input type="number" id="sub-resource-sequence-number" aria-describedby="sub-resource-sequence-number-helper-text" value={props.subResourceSequenceNumber} onChange={props.onSubResourceSequenceNumberChange} />
                                    <FormHelperText id="sub-resource-sequence-number-helper-text">The sub resource sequence number.</FormHelperText>
                                </FormControl>
                            </Grid>
                        ) : null
                    }
                </Grid>
            </Paper>
        </div >
    )
}

export default NamingContext;