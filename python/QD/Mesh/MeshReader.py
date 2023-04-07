# Copyright (c) 2021 QIDI B.V.
# QDTECH is released under the terms of the LGPLv3 or higher.

from typing import Union, List

import QD.Application
from QD.FileHandler.FileReader import FileReader
from QD.Logger import Logger
from QD.MimeTypeDatabase import MimeTypeDatabase, MimeTypeNotFoundError
from QD.Scene.SceneNode import SceneNode


class MeshReader(FileReader):
    def __init__(self) -> None:
        super().__init__()

    def read(self, file_name: str) -> Union[SceneNode, List[SceneNode]]:
        """Read mesh data from file and returns a node that contains the data 
        Note that in some cases you can get an entire scene of nodes in this way (eg; 3MF)

        :return: node :type{SceneNode} or :type{list(SceneNode)} The SceneNode or SceneNodes read from file.
        """

        result = self._read(file_name)
        QD.Application.Application.getInstance().getController().getScene().addWatchedFile(file_name)

        # The mesh reader may set a MIME type itself if it knows a more specific MIME type than just going by extension.
        # If not, automatically generate one from our MIME type database, going by the file extension.
        if not isinstance(result, list):
            meshes = [result]
        else:
            meshes = result
        for mesh in meshes:
            if mesh.source_mime_type is None:
                try:
                    mesh.source_mime_type = MimeTypeDatabase.getMimeTypeForFile(file_name)
                except MimeTypeNotFoundError:
                    Logger.warning(f"Loaded file {file_name} has no associated MIME type.")
                    # Leave MIME type at None then.

        return result

    def _read(self, file_name: str) -> Union[SceneNode, List[SceneNode]]:
        raise NotImplementedError("MeshReader plugin was not correctly implemented, no read was specified")
