import React from 'react'
import { CopyToClipboard } from "react-copy-to-clipboard";
import { IconButton, TableCell, TableRow, Tooltip, Typography } from '@material-ui/core'
import { FileCopy } from '@material-ui/icons'
import { getResourceName } from './NamingService';
import Alert from '@material-ui/lab/Alert';

const ResourceName = ({errors, name}) => {
    return (
        <Typography variant="p">
            {
                errors.length ? (
                    errors.map(item => <Alert variant="filled" severity="error">
                        {item}
                    </Alert>)
                ) : name
            }
        </Typography>
    )
}

const NameRow = (props) => {

    const resourceTypeText = props.resourceType.name.replaceAll('_', ' ')
    const nameResult = getResourceName(props)

    return (
        <TableRow hover role="checkbox" tabIndex={-1}>
            <TableCell>
                <Typography variant="p">
                    {resourceTypeText}
                </Typography>
            </TableCell>
            <TableCell>
                <ResourceName {...nameResult} />
            </TableCell>
            <TableCell>
                {
                    nameResult.errors.length === 0 ?
                        <CopyToClipboard
                            text={nameResult.name}
                            onCopy={() => props.setCopied(true)}>
                            <Tooltip title="Copy to clipboard">
                                <IconButton aria-label="copy to clipboard">
                                    <FileCopy />
                                </IconButton>
                            </Tooltip>
                        </CopyToClipboard>
                        : null
                }
            </TableCell>
        </TableRow>
    )
}

export default NameRow