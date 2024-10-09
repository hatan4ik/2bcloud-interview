import NameRow from './NameRow';
import { useState } from 'react';
import { TableContainer, Paper, Table, TableHead, TableBody, TableCell, TableRow, TablePagination } from '@material-ui/core';

const columns = [
    { id: 'resourceType', label: 'Resource Type' },
    { id: 'name', label: 'Name' },
    { id: 'action', label: 'Action' }
];


const NamesTable = (props) => {
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);

    const handleChangePage = (event, newPage) => {
        setPage(newPage);
    };

    const handleChangeRowsPerPage = (event) => {
        setRowsPerPage(+event.target.value);
        setPage(0);
    };

    return props.selectedResourceTypes.length > 0 && props.workloadName.length ?
        (
            <div style={{ padding: 16 }}>
                <Paper style={{ padding: 5 }} aria-level={3}>
                    <TableContainer size="small" >
                        <Table stickyHeader aria-label="">
                            <TableHead>
                                <TableRow>
                                    {columns.map((column) => (
                                        <TableCell key={column.id}>
                                            {column.label}
                                        </TableCell>
                                    ))}
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {props.selectedResourceTypes.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage).map((row) => {
                                    return (
                                        <NameRow key={row.code}
                                            setCopied={props.setCopied}
                                            resourceType={row}
                                            workloadName={props.workloadName}
                                            environment={props.environment}
                                            locationCode={props.locationCode}
                                            sequenceNumber={props.sequenceNumber}
                                            suffix={props.suffix}
                                            subResourceSequenceNumber={props.subResourceSequenceNumber} />
                                    );
                                })}
                            </TableBody>
                        </Table>
                    </TableContainer>
                    <TablePagination
                        rowsPerPageOptions={[10, 25, 100]}
                        component="div"
                        count={props.selectedResourceTypes.length}
                        rowsPerPage={rowsPerPage}
                        page={page}
                        onChangePage={handleChangePage}
                        onChangeRowsPerPage={handleChangeRowsPerPage}
                    />
                </Paper>
            </div>
        ) : null
}


export default NamesTable