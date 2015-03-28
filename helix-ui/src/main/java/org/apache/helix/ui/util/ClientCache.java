package org.apache.helix.ui.util;

import com.google.common.cache.*;
import org.I0Itec.zkclient.exception.ZkTimeoutException;
import org.apache.helix.manager.zk.ZNRecordSerializer;
import org.apache.helix.manager.zk.ZkClient;
import org.apache.helix.ui.api.ClusterConnection;
import org.apache.zookeeper.ZooKeeper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import java.net.URLDecoder;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

public class ClientCache {
    private static final Logger LOG = LoggerFactory.getLogger(ClientCache.class);
    private static final int DEFAULT_SESSION_TIMEOUT_MILLIS = 5000;
    private static final int DEFAULT_CONNECTION_TIMEOUT_MILLIS = 5000;

    private final ZkAddressValidator zkAddressValidator;

    public ClientCache(ZkAddressValidator zkAddressValidator) {
        this.zkAddressValidator = zkAddressValidator;
    }

    // Manages and caches lifecycle of connections to ZK
    final LoadingCache<String, ClusterConnection> clientCache = CacheBuilder.newBuilder()
            .maximumSize(3)
            .expireAfterAccess(5, TimeUnit.MINUTES)
            .removalListener(new RemovalListener<String, ClusterConnection>() {
                @Override
                public void onRemoval(RemovalNotification<String, ClusterConnection> removalNotification) {
                    if (removalNotification.getValue() != null) {
                        ZkClient zkClient = removalNotification.getValue().getZkClient();
                        if (zkClient != null) {
                            zkClient.close();
                            LOG.info("Disconnected from {}", removalNotification.getKey());
                        }
                    }
                }
            })
            .build(new CacheLoader<String, ClusterConnection>() {
                @Override
                public ClusterConnection load(String zkAddress) throws Exception {
                    ZkClient zkClient = new ZkClient(
                            zkAddress,
                            DEFAULT_SESSION_TIMEOUT_MILLIS,
                            DEFAULT_CONNECTION_TIMEOUT_MILLIS,
                            new ZNRecordSerializer());
                    zkClient.waitUntilConnected();
                    LOG.info("Connected to {}", zkAddress);
                    return new ClusterConnection(zkClient);
                }
            });

    public ClusterConnection get(String zkAddress) {
        try {
            zkAddress = URLDecoder.decode(zkAddress, "UTF-8");
        } catch (Exception e) {
            throw new IllegalArgumentException(e);
        }

        if (!zkAddressValidator.validate(zkAddress)) {
            throw new WebApplicationException("Cannot access " + zkAddress, Response.Status.UNAUTHORIZED);
        }

        ClusterConnection clusterConnection;
        try {
            clusterConnection = clientCache.get(zkAddress);
        } catch (Exception e) {
            throw new WebApplicationException(e, Response.Status.GATEWAY_TIMEOUT);
        }

        if (!clusterConnection.getZkClient().getConnection().getZookeeperState().equals(ZooKeeper.States.CONNECTED)) {
            clientCache.invalidate(zkAddress);
            throw new WebApplicationException("ZooKeeper connection was dead", Response.Status.GATEWAY_TIMEOUT);
        }

        return clusterConnection;
    }

    public void invalidateAll() {
        clientCache.invalidateAll();
    }

    public Set<String> getDeadConnections() {
        Set<String> deadConnections = new HashSet<String>();
        for (Map.Entry<String, ClusterConnection> entry : clientCache.asMap().entrySet()) {
            if (!entry.getValue().getZkClient().getConnection().getZookeeperState().isAlive()) {
                deadConnections.add(entry.getKey());
            }
        }
        return deadConnections;
    }
}
