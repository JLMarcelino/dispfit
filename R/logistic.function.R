logistic.function <- function (data, chi.res.hist, ks.res.hist) {

log.dist.logistic <- function (par, r) {
  a <- par[1] ## location, mean
  b <- par[2] ## scale
  flogistic <- (b / (2 * pi * (a^2) * gamma(2/b) * gamma(1-(2/b)) )) * ((1 + ((r^b) / (a^b)))^(-1))
  -sum(log(flogistic)) ## Negative Log Likelihood
}
dist.logistic <- function (r, a, b) {
  flogistic <- 2*pi*r*(b / (2 * pi * (a^2) * gamma(2/b) * gamma(1-(2/b)) )) * ((1 + ((r^b) / (a^b)))^(-1))
}
# initial values estimation
# n <- length(data)
# location <- mean(data)
# v <- (n - 1)/n * var(data)
# scale <- sqrt(3 * v)/pi

while (TRUE) {
  SANN.logistic.opt <- optim (par = c(1, 3), ## valor inicial para o "a"
                              fn = log.dist.logistic, ## função a minimizar
                              r = data,
                              method = "SANN",
                              # lower = c(0, 0),
                              control = list(maxit = 10000))
  try.logistic <- try(
    dist.logistic.opt.try <- optim (par = c(SANN.logistic.opt$par[1], SANN.logistic.opt$par[2]), ## valor inicial para o "a"
                                    fn = log.dist.logistic, ## função a minimizar
                                    r = data,
                                    method = "L-BFGS-B",
                                    lower = c(0.000001, 2.000001),
                                    upper = c(Inf, Inf),
                                    control = list(maxit = 10000)),
    silent=T)

  if (class(try.logistic) != "try-error") {
    dist.logistic.opt.try
    break
  }
}
# optimization procedure
dist.logistic.opt <- dist.logistic.opt.try
# dist.logistic.opt <- optim (par = c(location, scale), ## valor inicial para o "a"
#                          fn = log.dist.logistic, ## função a minimizar
#                          r = data, ## dados
#                          method = "L-BFGS-B", ## método quando para estimar apenas um parametro (par)
#                          lower = c(0.00001, 2.00001), ## limite inferior do parametro
#                          upper = c(Inf, Inf), ## limite superior do parametro
#                          hessian = T)

# output values
# AIC
aic.logistic <- 2 * length(dist.logistic.opt$par) + 2 * dist.logistic.opt$value
# AICc
aicc.logistic <- aic.logistic + (2 * length(dist.logistic.opt$par)^2 + 2 * length(dist.logistic.opt$par))/(length(data) - length(dist.logistic.opt$par) - 1 )
# BIC
bic.logistic <-  2 * dist.logistic.opt$value + length(dist.logistic.opt$par)*log(length(data))
# Chi-squared
chi.expected.values.logistic <- dist.logistic(chi.res.hist$mids, dist.logistic.opt$par[1], dist.logistic.opt$par[2])*length(data)*(chi.res.hist$breaks[2] - chi.res.hist$breaks[1])
chi.squared.statistic.logistic <- sum((chi.res.hist$counts - chi.expected.values.logistic)^2 / chi.expected.values.logistic)
chi.squared.pvalue.logistic <- 1-pchisq(chi.squared.statistic.logistic, length(chi.res.hist$counts)-3)
# Kolmogorov-Smirnov
ks.expected.values.logistic <- dist.logistic(ks.res.hist$mids, dist.logistic.opt$par[1], dist.logistic.opt$par[2])*length(data)*(ks.res.hist$breaks[2] - ks.res.hist$breaks[1])
simul.logistic <- c()
for (i in seq_along(ks.res.hist$mids)) {
  simul.logistic <- c(simul.logistic, rep(ks.res.hist$mids[i], round(ks.expected.values.logistic[i], 0)))
}
ks.logistic <- ks.test(data, simul.logistic)
g.max.logistic <- as.numeric(ks.logistic$statistic)
KS.logistic <- as.numeric(ks.logistic$p.value)

# cumulative.expected.values.logistic <- c(expected.values.logistic[1])
# for (i in 1+seq_along(expected.values.logistic)) {
#   cumulative.expected.values.logistic[i] <- cumulative.expected.values.logistic[i-1] + expected.values.logistic[i]
# }
# cumulative.expected.values.logistic <- cumulative.expected.values.logistic/sum(expected.values.logistic)
# cumulative.expected.values.logistic <- cumulative.expected.values.logistic[!is.na(cumulative.expected.values.logistic)]
# g.max.logistic <- max(abs(cumulative.data - cumulative.expected.values.logistic))
# if (g.max.logistic < (sqrt(-log(0.01/2)/(2*length(cumulative.data))) * (1/(2*length(cumulative.data))))) {
#   KS.logistic <- "Accept"
# } else {KS.logistic <- "Reject"}
# parameter estimate
par.1.logistic <- dist.logistic.opt$par[1]
par.2.logistic <- dist.logistic.opt$par[2]
# parameter estimate standard error
par.1.se.logistic <- sqrt(diag(solve(numDeriv::hessian(log.dist.logistic, x=dist.logistic.opt$par, r=data))))[1]
par.2.se.logistic <- sqrt(diag(solve(numDeriv::hessian(log.dist.logistic, x=dist.logistic.opt$par, r=data))))[2]
# mean dispersal distance
mean.logistic <- dist.logistic.opt$par[1] * (( gamma(3/dist.logistic.opt$par[2]) * gamma(1-(3/dist.logistic.opt$par[2])) ) /
                                               ( gamma(2/dist.logistic.opt$par[2]) * gamma(1-(2/dist.logistic.opt$par[2])) ) )

mean.logistic <- dist.logistic.opt$par[1]^(1/dist.logistic.opt$par[2]) * (( gamma(3/dist.logistic.opt$par[2]) * gamma(1-(3/dist.logistic.opt$par[2])) ) /
                                                                            ( gamma(2/dist.logistic.opt$par[2]) * gamma(1-(2/dist.logistic.opt$par[2])) ) )

mean.stderr.logistic <- msm::deltamethod(~ x1 * ((gamma(3/x2) * gamma(1-(3/x2))) / (gamma(2/x2) * gamma(1-(2/x2))) ), mean = dist.logistic.opt$par, cov = solve(numDeriv::hessian(log.dist.logistic, x=dist.logistic.opt$par, r=data)) )
# variance
variance.logistic <- "in progress"
# 1, 1/b, 1 + 1/b, -a^(-b) r^b
# x <- 1000
# par.2.logistic*x*hypergeo::hypergeo_buhring(1, 1/par.2.logistic, 1 + 1/par.2.logistic, -par.1.logistic^(-par.2.logistic)* x^par.2.logistic)
#
# ((x^2)/2)*(par.1.logistic^-par.2.logistic)*hypergeo::hypergeo_buhring(1, 2/par.2.logistic, (par.2.logistic+2)/par.2.logistic, -par.1.logistic^(-par.2.logistic) * x^par.2.logistic)
#
#
#
#
# buhring_eqn11
# hypergeo
variance.stderr.logistic <-"in progress"
# skewness
skewness.logistic <- "in progress"
skewness.stderr.logistic <- "in progress"
# kurtosis
kurtosis.logistic <- "in progress"
kurtosis.stderr.logistic <- "in progress"
# output
res <- data.frame(aic.logistic, aicc.logistic, bic.logistic,
                              chi.squared.statistic.logistic, chi.squared.pvalue.logistic,g.max.logistic, KS.logistic,
                              par.1.logistic, par.1.se.logistic, par.2.logistic, par.2.se.logistic,
                              mean.logistic, mean.stderr.logistic, variance.logistic, variance.stderr.logistic,
                              skewness.logistic, skewness.stderr.logistic, kurtosis.logistic, kurtosis.stderr.logistic)
logistic.values <- list("opt" = dist.logistic.opt, "res" = res)
}
